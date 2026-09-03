"""
PRAMAAN - Voice Evidence Extraction Agent

Responsibilities
----------------
1. Accept an ASR transcript from the frontend.
2. Use Gemini for multilingual semantic extraction.
3. Preserve evidence for every extracted field.
4. Normalize agricultural values into canonical representations.
5. Never invent missing information.
6. Provide a deterministic fallback if Gemini is unavailable.
7. Return a stable VoiceLogResponse for the API/frontend.

Architecture
------------
Farmer
   ↓
ASR / Speech-to-Text
   ↓
Voice Agent
   ├── Gemini semantic extraction
   ├── Evidence preservation
   ├── Normalization
   └── Structural validation
   ↓
Validation Agent
"""

import logging
import re
from typing import Any, Dict, Optional

from google import genai
from google.genai import types
from pydantic import BaseModel, Field, ValidationError

from backend.app.core.config import settings
from backend.app.models.schemas import (
    VoiceLogRequest,
    VoiceLogResponse,
)


logger = logging.getLogger(__name__)


# ============================================================
# CONFIGURATION
# ============================================================

VOICE_MODEL = getattr(
    settings,
    "VOICE_MODEL",
    "gemini-3.7-flash",
)


# ============================================================
# CONTROLLED ACTION VOCABULARY
# ============================================================

SUPPORTED_ACTIONS = {
    "SPRAY",
    "OBSERVE",
    "IRRIGATE",
    "FERTILIZE",
    "HARVEST",
}


# ============================================================
# OPTIONAL FALLBACK VOCABULARY
# ============================================================
#
# IMPORTANT:
# These aliases are NOT the primary multilingual extraction
# mechanism.
#
# Gemini performs semantic understanding.
#
# These mappings exist only as an evidence-preserving fallback
# when Gemini is unavailable.
#
# Do NOT keep expanding this indefinitely.
# For production, these should eventually come from a managed
# agricultural ontology / product registry.
# ============================================================

CROP_ALIASES = {
    "cotton": "Cotton",
    "कापूस": "Cotton",
    "कपास": "Cotton",

    "chilli": "Chilli",
    "chili": "Chilli",
    "मिर्च": "Chilli",
    "मिरची": "Chilli",

    "wheat": "Wheat",
    "गेहूं": "Wheat",
    "गहू": "Wheat",

    "paddy": "Paddy",
    "rice": "Paddy",
    "धान": "Paddy",
    "तांदूळ": "Paddy",

    "tomato": "Tomato",
    "टमाटर": "Tomato",
    "टोमॅटो": "Tomato",
}


PEST_ALIASES = {
    "whitefly": "Whitefly",
    "white fly": "Whitefly",
    "पांढरी माशी": "Whitefly",
    "पांढऱ्या माशी": "Whitefly",

    "thrips": "Thrips",
    "thrip": "Thrips",
    "ट्रिप्स": "Thrips",
    "थ्रिप्स": "Thrips",
    "फुलकिडे": "Thrips",
    "फुलकिडा": "Thrips",

    "jassid": "Jassid",
    "jassids": "Jassid",
    "leafhopper": "Jassid",
    "leaf hopper": "Jassid",
    "leafhoppers": "Jassid",
    "तुडतुडे": "Jassid",
    "तुडतुड": "Jassid",
    "तुडतुडा": "Jassid",
    "तुडतुड्या": "Jassid",

    "bollworm": "Bollworm",
    "boll worm": "Bollworm",
    "बोंडअळी": "Bollworm",

    "rust": "Rust",
    "yellow rust": "Yellow Rust",
    "रतुआ": "Yellow Rust",
}


PRODUCT_ALIASES = {
    "bio neem": "Bio-Neem",
    "bio-neem": "Bio-Neem",
    "bio neem power": "Bio-Neem Power",

    "pegasus": "Pegasus",
    "pegasus 50% wp": "Pegasus 50% WP",

    "coragen": "Coragen",
    "tilt": "Tilt",
    "nano urea": "Nano Urea",

    # Speech-recognition spellings commonly observed
    # in current supported-language testing.
    "पेगॅसस": "Pegasus",
    "पेगासस": "Pegasus",
    "पॅगॅसस": "Pegasus",
}


ACTION_ALIASES = {
    "spray": "SPRAY",
    "sprayed": "SPRAY",
    "spraying": "SPRAY",

    "फवारणी": "SPRAY",
    "छिड़काव": "SPRAY",

    "observe": "OBSERVE",
    "observed": "OBSERVE",
    "seen": "OBSERVE",

    "दिसले": "OBSERVE",
    "दिसत": "OBSERVE",

    "irrigate": "IRRIGATE",
    "irrigated": "IRRIGATE",
    "irrigation": "IRRIGATE",

    "पाणी": "IRRIGATE",

    "fertilize": "FERTILIZE",
    "fertilized": "FERTILIZE",
    "fertilizer": "FERTILIZE",

    "खत": "FERTILIZE",

    "harvest": "HARVEST",
    "harvested": "HARVEST",

    "कापणी": "HARVEST",
}


# ============================================================
# LANGUAGE-INDEPENDENT NUMBER NORMALIZATION
# ============================================================
#
# These are normalization helpers, NOT the semantic extraction
# engine.
#
# Gemini should understand language-specific number words.
#
# These mappings are retained only as deterministic recovery
# for the currently tested Marathi transcripts.
# ============================================================

MARATHI_NUMBER_WORDS = {
    "शंभर": "100",
    "दोनशे": "200",
    "अडीचशे": "250",
    "तीनशे": "300",
    "चारशे": "400",
    "पाचशे": "500",
    "सहाशे": "600",
    "सातशे": "700",
    "आठशे": "800",
    "नऊशे": "900",
}


MARATHI_DIGITS = str.maketrans(
    "०१२३४५६७८९",
    "0123456789",
)


# ============================================================
# EVIDENCE FIELD
# ============================================================

class ExtractedField(BaseModel):
    """
    Represents one extracted field together with evidence.

    value:
        Canonical normalized value.

    source_text:
        Exact or near-exact phrase from the transcript supporting
        the value.

    confidence:
        Confidence in interpreting this specific field.

    Important:
        Confidence does NOT mean that the farmer's claim is true.
    """

    value: Optional[str] = Field(
        default=None,
        description=(
            "Canonical normalized value extracted from the transcript. "
            "Null if the field is not reliably established."
        ),
    )

    source_text: Optional[str] = Field(
        default=None,
        description=(
            "Transcript phrase that directly supports this field. "
            "Must not be invented."
        ),
    )

    confidence: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
        description=(
            "Confidence that the source text was correctly interpreted "
            "as the field value. This is not truthfulness confidence."
        ),
    )


# ============================================================
# LLM OUTPUT SCHEMA
# ============================================================

class VoiceExtractionResult(BaseModel):
    """
    Structured interpretation of the farmer's transcript.

    Every extracted field retains:
        value
        source_text
        confidence

    This makes the extraction traceable for downstream validation.
    """

    cleaned_transcript: str = Field(
        description=(
            "Minimally corrected transcript. "
            "Preserve the farmer's original meaning. "
            "Do not add facts."
        )
    )

    crop: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Crop explicitly mentioned in the transcript."
        ),
    )

    action_type: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Agricultural action. Canonical value must be one of "
            "SPRAY, OBSERVE, IRRIGATE, FERTILIZE, HARVEST."
        ),
    )

    product_mentioned: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Agricultural product explicitly mentioned."
        ),
    )

    dosage: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Explicitly stated application quantity or dosage."
        ),
    )

    target_pest: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Explicitly mentioned pest or disease."
        ),
    )

    plot_name: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Explicit plot, field, group, or parcel identifier."
        ),
    )

    observation_time: ExtractedField = Field(
        default_factory=ExtractedField,
        description=(
            "Explicit date/time or relative time expression."
        ),
    )

    confidence: float = Field(
        ge=0.0,
        le=1.0,
        description=(
            "Overall interpretation confidence. "
            "Not truthfulness confidence."
        ),
    )

    missing_information: list[str] = Field(
        default_factory=list,
        description=(
            "Important fields not established by the transcript."
        ),
    )

    ambiguous_information: list[str] = Field(
        default_factory=list,
        description=(
            "Fields whose interpretation is uncertain or ambiguous."
        ),
    )

    needs_clarification: bool = Field(
        default=False,
        description=(
            "True if ambiguity materially affects downstream "
            "agricultural analysis."
        ),
    )

    clarification_question: Optional[str] = Field(
        default=None,
        description=(
            "Short farmer-friendly clarification question."
        ),
    )


# ============================================================
# VOICE AGENT
# ============================================================

class VoiceAgent:

    def __init__(self):

        self.api_key = settings.GEMINI_API_KEY

        self.client = None

        if self.api_key:
            try:
                self.client = genai.Client(
                    api_key=self.api_key
                )

                logger.info(
                    "Gemini client initialized for Voice Agent."
                )

            except Exception as exc:
                logger.exception(
                    "Failed to initialize Gemini client: %s",
                    exc,
                )

        else:
            logger.warning(
                "GEMINI_API_KEY is not configured. "
                "Voice Agent will use deterministic fallback."
            )

    # ========================================================
    # PUBLIC ENTRY POINT
    # ========================================================

    def process_voice_transcript(
        self,
        request: VoiceLogRequest,
    ) -> VoiceLogResponse:

        # ----------------------------------------------------
        # 1. INPUT VALIDATION
        # ----------------------------------------------------

        transcript = (
            request.audio_transcript or ""
        ).strip()

        if not transcript:
            raise ValueError(
                "audio_transcript is required. "
                "The Voice Agent cannot extract information "
                "from empty input."
            )

        language = (
            request.language or "unknown"
        ).strip().lower()

        # ----------------------------------------------------
        # 2. GEMINI SEMANTIC EXTRACTION
        # ----------------------------------------------------

        extraction: Optional[VoiceExtractionResult] = None

        extraction_method = "RULE_BASED"

        if self.client:

            try:

                extraction = self._extract_with_llm(
                    transcript=transcript,
                    language=language,
                )

                extraction_method = "LLM"

                logger.info(
                    "Voice extraction completed using Gemini."
                )

            except Exception as exc:

                logger.exception(
                    "LLM voice extraction failed: %s",
                    exc,
                )

        # ----------------------------------------------------
        # 3. DETERMINISTIC FALLBACK
        # ----------------------------------------------------

        if extraction is None:

            logger.warning(
                "Using evidence-preserving deterministic "
                "voice fallback."
            )

            extraction = self._rule_based_fallback(
                transcript=transcript,
            )

            extraction_method = "RULE_BASED"

        # ----------------------------------------------------
        # 4. DETERMINISTIC NORMALIZATION
        # ----------------------------------------------------

        extraction = self._normalize_extraction(
            extraction=extraction,
            original_transcript=transcript,
        )

        # ----------------------------------------------------
        # 5. SEMANTIC / STRUCTURAL VALIDATION
        # ----------------------------------------------------

        extraction = self._validate_extraction(
            extraction=extraction,
            original_transcript=transcript,
        )

        # ----------------------------------------------------
        # 6. BUILD API RESPONSE
        # ----------------------------------------------------

        return self._build_response(
            request=request,
            transcript=transcript,
            language=language,
            extraction=extraction,
            extraction_method=extraction_method,
        )

    # ========================================================
    # GEMINI EXTRACTION
    # ========================================================

    def _extract_with_llm(
        self,
        transcript: str,
        language: str,
    ) -> VoiceExtractionResult:

        prompt = f"""
You are the PRAMAAN Voice Evidence Extraction Agent.

Your job is to convert a farmer's speech-to-text transcript
into structured agricultural evidence.

Supported application languages for the current PRAMAAN system:
- English
- Hindi
- Marathi

The transcript may contain:
- one supported language
- mixed English/Hindi/Marathi
- transliterated agricultural terms
- speech-recognition errors
- colloquial farmer terminology

INPUT LANGUAGE:
{language}

RAW TRANSCRIPT:
{transcript}


============================================================
CORE PRINCIPLE
============================================================

Extract ONLY information supported by the transcript.

Never invent missing information.

If a field cannot be established reliably:
    value = null
    source_text = null
    confidence = 0

The farmer's statement is an observation or claim.

It is NOT automatically verified truth.


============================================================
MULTILINGUAL SEMANTIC UNDERSTANDING
============================================================

Do NOT require exact English words.

Understand the semantic meaning of agricultural phrases
regardless of whether the farmer speaks English, Hindi,
Marathi, or mixes them.

Do not rely on hard-coded language mappings.

For example, a phrase meaning:
- spraying
- a crop
- a pest
- a product
- a quantity
- a plot

should be understood semantically.

Normalize the extracted result into the canonical schema.

Do not add information simply because a particular crop,
pest, or product is common in agriculture.


============================================================
EVIDENCE REQUIREMENT
============================================================

For EVERY extracted field, provide:

value:
    Canonical normalized value.

source_text:
    The actual phrase from the transcript that supports it.

confidence:
    Confidence in interpreting that phrase.

The source_text must be supported by the transcript.

Never fabricate evidence.


============================================================
WHAT MUST NEVER BE INFERRED
============================================================

Never infer:

- crop from product
- product from crop
- product from pest
- dosage from product
- dosage from crop
- pest from crop
- pest from product
- plot from GPS
- plot from farm ID
- action from unrelated context
- treatment effectiveness
- farmer truthfulness
- weather conditions
- agronomic recommendations


============================================================
CROP
============================================================

Extract the crop only when the transcript identifies it.

Return the canonical English crop name.

Examples of acceptable semantic normalization:

A farmer may say:
    cotton
    कपास
    कापूस

The output should represent the same crop canonically.

Do NOT select a crop merely because another field suggests it.


============================================================
ACTION
============================================================

Normalize the agricultural action to one of:

SPRAY
OBSERVE
IRRIGATE
FERTILIZE
HARVEST

If no supported action is reliably established:

value = null


============================================================
PRODUCT
============================================================

Extract an agricultural product only when the farmer
explicitly mentions it.

Preserve the product identity.

Correct obvious ASR spelling/phonetic errors only when
the surrounding transcript provides strong evidence.

Do NOT replace an unknown product with a common product.


============================================================
PEST / DISEASE
============================================================

Extract only when the transcript explicitly identifies
the pest or disease.

If a regional agricultural term has a well-established
meaning, normalize it to the canonical English agricultural
name.

Do not guess a pest from crop or treatment.


============================================================
DOSAGE / QUANTITY
============================================================

Extract explicit quantities.

Understand:
- numeric digits
- number words
- multilingual number expressions
- speech-recognition variants
- units
- application volume
- water volume

Normalize to a canonical representation when the meaning
is unambiguous.

Examples:

250 ml
250 ml in 200 L water
2 kg per acre

Do NOT calculate a missing quantity.

Do NOT infer dosage from a product.


============================================================
PLOT / FIELD
============================================================

Extract an explicit plot, field, group, parcel, or similar
identifier.

Examples of the semantic concept include:

"plot number three"
"field 3"
"plot no. 3"

Normalize to a consistent representation such as:

Plot 3

Do NOT infer a plot from:
- GPS
- farm ID
- crop
- product
- previous context


============================================================
TIME
============================================================

Extract only explicit temporal information.

Examples:

today
yesterday
this morning
at 10 AM
on Monday

Do not invent a date when the transcript only says
"today".

Do not silently convert relative time into an absolute date
unless the input explicitly provides enough information.


============================================================
CLEANED TRANSCRIPT
============================================================

Produce a minimally corrected transcript.

You may correct obvious ASR errors when the meaning is clear.

Do NOT add facts.

Do not introduce:
- crops
- pests
- products
- quantities
- plots
- dates
- actions

that were not present in the original transcript.


============================================================
CONFIDENCE
============================================================

Overall confidence represents confidence in interpretation.

It does NOT mean:

- the farmer is truthful
- the product is genuine
- the treatment happened
- the treatment was appropriate
- the treatment was effective

Use the 0.0 to 1.0 range honestly.

Field-level confidence should reflect uncertainty for
that specific field.

Overall confidence should reflect the quality of the
interpretation as a whole.


============================================================
MISSING INFORMATION
============================================================

Important fields that are not established should appear
in missing_information.

Possible fields:

crop
action_type
product_mentioned
dosage
target_pest
plot_name

Only include fields that are genuinely missing.


============================================================
AMBIGUITY
============================================================

If a field has multiple plausible interpretations,
record that field in ambiguous_information.

Do not force a value just to complete the schema.


============================================================
CLARIFICATION
============================================================

Set needs_clarification=true when an unresolved ambiguity
could materially affect downstream agricultural analysis.

Ask a short farmer-friendly question.

For example:

"Which product did you use?"

or

"Which plot was this observation from?"

Do not ask unnecessary questions.


============================================================
IMPORTANT
============================================================

Return ONLY the structured schema.

Do not return explanations outside the schema.
"""

        response = self.client.models.generate_content(
            model=VOICE_MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=VoiceExtractionResult,
            ),
        )

        if not response.text:
            raise ValueError(
                "Gemini returned an empty response."
            )

        try:

            return VoiceExtractionResult.model_validate_json(
                response.text
            )

        except ValidationError as exc:

            logger.error(
                "Structured voice output validation failed: %s",
                exc,
            )

            raise

    # ========================================================
    # DETERMINISTIC FALLBACK
    # ========================================================

    def _rule_based_fallback(
        self,
        transcript: str,
    ) -> VoiceExtractionResult:

        text = transcript.lower()

        crop_value = self._find_alias(
            text,
            CROP_ALIASES,
        )

        action_value = self._find_alias(
            text,
            ACTION_ALIASES,
        )

        pest_value = self._find_alias(
            text,
            PEST_ALIASES,
        )

        product_value = self._find_alias(
            text,
            PRODUCT_ALIASES,
        )

        dosage_value = self._extract_dosage(
            transcript,
        )

        crop = self._make_fallback_field(
            value=crop_value,
            transcript=transcript,
            confidence=0.80,
        )

        action = self._make_fallback_field(
            value=action_value,
            transcript=transcript,
            confidence=0.80,
        )

        pest = self._make_fallback_field(
            value=pest_value,
            transcript=transcript,
            confidence=0.80,
        )

        product = self._make_fallback_field(
            value=product_value,
            transcript=transcript,
            confidence=0.80,
        )

        dosage = self._make_fallback_field(
            value=dosage_value,
            transcript=transcript,
            confidence=0.75,
        )

        # ----------------------------------------------------
        # Missing fields
        # ----------------------------------------------------

        missing = []

        if crop.value is None:
            missing.append("crop")

        if action.value is None:
            missing.append("action_type")

        if product.value is None:
            missing.append("product_mentioned")

        if dosage.value is None:
            missing.append("dosage")

        if pest.value is None:
            missing.append("target_pest")

        missing.append("plot_name")

        # ----------------------------------------------------
        # Fallback confidence
        # ----------------------------------------------------

        confidence = self._fallback_confidence(
            crop=crop.value,
            action=action.value,
            product=product.value,
            dosage=dosage.value,
            pest=pest.value,
        )

        return VoiceExtractionResult(
            cleaned_transcript=transcript,

            crop=crop,

            action_type=action,

            product_mentioned=product,

            dosage=dosage,

            target_pest=pest,

            plot_name=ExtractedField(),

            observation_time=ExtractedField(),

            confidence=confidence,

            missing_information=missing,

            ambiguous_information=[],

            needs_clarification=False,

            clarification_question=None,
        )

    # ========================================================
    # FALLBACK FIELD CREATOR
    # ========================================================

    @staticmethod
    def _make_fallback_field(
        *,
        value: Optional[str],
        transcript: str,
        confidence: float,
    ) -> ExtractedField:

        if value is None:

            return ExtractedField(
                value=None,
                source_text=None,
                confidence=0.0,
            )

        return ExtractedField(
            value=value,
            source_text=transcript,
            confidence=confidence,
        )

    # ========================================================
    # ALIAS MATCHING
    # ========================================================

    @staticmethod
    def _find_alias(
        text: str,
        aliases: Dict[str, str],
    ) -> Optional[str]:

        # Longest aliases first.
        #
        # This avoids:
        #
        # "white fly"
        #
        # being incorrectly matched as two independent words
        # before the complete phrase is considered.

        for alias in sorted(
            aliases.keys(),
            key=len,
            reverse=True,
        ):

            if alias.lower() in text:

                return aliases[alias]

        return None

    # ========================================================
    # NUMBER NORMALIZATION
    # ========================================================

    @staticmethod
    def _normalize_marathi_numbers(
        text: str,
    ) -> str:

        text = text.translate(
            MARATHI_DIGITS
        )

        for word, number in MARATHI_NUMBER_WORDS.items():

            text = text.replace(
                word,
                number,
            )

        return text

    # ========================================================
    # UNIT NORMALIZATION
    # ========================================================

    @staticmethod
    def _normalize_units(
        text: str,
    ) -> str:

        replacements = {

            # Marathi
            "मिलीलीटर": "ml",
            "मिलीलिटर": "ml",
            "मिली लिटर": "ml",
            "मिली": "ml",
            "मि.ली.": "ml",

            "लिटरमध्ये": "L",
            "लिटर": "L",

            # Hindi
            "मिलीलीटर": "ml",
            "मिलीलीटर": "ml",
            "मिलीलीटर": "ml",

            "लीटर": "L",
            "लीटर में": "L",

            # English
            "milliliters": "ml",
            "milliliter": "ml",
            "millilitres": "ml",
            "millilitre": "ml",

            "liters": "L",
            "liter": "L",
            "litres": "L",
            "litre": "L",
        }

        normalized = text

        for old, new in replacements.items():

            normalized = normalized.replace(
                old,
                new,
            )

        return normalized

    # ========================================================
    # DOSAGE EXTRACTION
    # ========================================================

    @staticmethod
    def _extract_dosage(
        text: str,
    ) -> Optional[str]:

        # ----------------------------------------------------
        # Normalize known number forms.
        # ----------------------------------------------------

        text = VoiceAgent._normalize_marathi_numbers(
            text
        )

        text = VoiceAgent._normalize_units(
            text
        )

        # ----------------------------------------------------
        # Pattern 1:
        #
        # 250 ml ... 200 L
        #
        # Example:
        #
        # 250 ml औषध 200 लिटर पाण्यात
        # ----------------------------------------------------

        pattern = (
            r"(\d+(?:\.\d+)?)\s*ml"
            r".{0,40}?"
            r"(\d+(?:\.\d+)?)\s*L"
        )

        match = re.search(
            pattern,
            text,
            flags=re.IGNORECASE,
        )

        if match:

            amount = match.group(1)
            water = match.group(2)

            return (
                f"{amount} ml "
                f"in {water} L water"
            )

        # ----------------------------------------------------
        # Pattern 2:
        #
        # 250 ml in 200 L
        # ----------------------------------------------------

        pattern = (
            r"(\d+(?:\.\d+)?)\s*ml\s*"
            r"(?:in|per)\s*"
            r"(\d+(?:\.\d+)?)\s*L"
        )

        match = re.search(
            pattern,
            text,
            flags=re.IGNORECASE,
        )

        if match:

            amount = match.group(1)
            water = match.group(2)

            return (
                f"{amount} ml "
                f"in {water} L water"
            )

        # ----------------------------------------------------
        # Pattern 3:
        #
        # quantity per acre
        #
        # Example:
        # 250 ml per acre
        # ----------------------------------------------------

        pattern = (
            r"(\d+(?:\.\d+)?)\s*"
            r"(ml|kg|g|L)\s*"
            r"(?:per|/)\s*acre"
        )

        match = re.search(
            pattern,
            text,
            flags=re.IGNORECASE,
        )

        if match:

            return (
                f"{match.group(1)} "
                f"{match.group(2)} per acre"
            )

        # ----------------------------------------------------
        # Pattern 4:
        #
        # Simple quantity
        #
        # Example:
        # 250 ml
        # 2 kg
        # ----------------------------------------------------

        pattern = (
            r"\b"
            r"(\d+(?:\.\d+)?)"
            r"\s*"
            r"(ml|L|kg|g)"
            r"\b"
        )

        match = re.search(
            pattern,
            text,
            flags=re.IGNORECASE,
        )

        if match:

            return (
                f"{match.group(1)} "
                f"{match.group(2)}"
            )

        return None

    # ========================================================
    # NORMALIZATION
    # ========================================================

    def _normalize_extraction(
        self,
        extraction: VoiceExtractionResult,
        original_transcript: str,
    ) -> VoiceExtractionResult:

        # ----------------------------------------------------
        # Action normalization
        # ----------------------------------------------------

        if extraction.action_type.value:

            action = (
                extraction.action_type.value
                .strip()
                .upper()
            )

            if action in SUPPORTED_ACTIONS:

                extraction.action_type.value = action

            else:

                # Try fallback aliases only if the value itself
                # can be recognized.

                alias = self._find_alias(
                    action.lower(),
                    ACTION_ALIASES,
                )

                if alias in SUPPORTED_ACTIONS:

                    extraction.action_type.value = alias

                else:

                    extraction.action_type = ExtractedField(
                        value=None,
                        source_text=extraction.action_type.source_text,
                        confidence=0.0,
                    )

                    if (
                        "action_type"
                        not in extraction.ambiguous_information
                    ):

                        extraction.ambiguous_information.append(
                            "action_type"
                        )

        # ----------------------------------------------------
        # Normalize whitespace in field values.
        # ----------------------------------------------------

        fields = [
            "crop",
            "action_type",
            "product_mentioned",
            "dosage",
            "target_pest",
            "plot_name",
            "observation_time",
        ]

        for field_name in fields:

            field = getattr(
                extraction,
                field_name,
            )

            if field is None:
                setattr(
                    extraction,
                    field_name,
                    ExtractedField(),
                )
                continue

            if field.value is not None:

                field.value = field.value.strip()

                if not field.value:

                    field.value = None

            if field.source_text is not None:

                field.source_text = (
                    field.source_text.strip()
                )

                if not field.source_text:

                    field.source_text = None

        # ----------------------------------------------------
        # Dosage deterministic recovery
        #
        # This is deliberately AFTER Gemini extraction.
        #
        # Gemini remains the semantic extractor.
        #
        # This layer only recovers an explicitly present
        # quantity when the structured result omitted it.
        # ----------------------------------------------------

        if extraction.dosage.value is None:

            recovered_dosage = self._extract_dosage(
                original_transcript
            )

            if recovered_dosage:

                extraction.dosage = ExtractedField(
                    value=recovered_dosage,
                    source_text=self._find_dosage_source(
                        original_transcript
                    ),
                    confidence=0.75,
                )

        # ----------------------------------------------------
        # Plot recovery
        #
        # We intentionally do NOT use a hard-coded language
        # parser here.
        #
        # Gemini is responsible for plot semantics.
        #
        # Only simple numeric English-format recovery is used
        # as a safe fallback.
        # ----------------------------------------------------

        if extraction.plot_name.value is None:

            plot = self._extract_simple_plot_identifier(
                original_transcript
            )

            if plot:

                extraction.plot_name = ExtractedField(
                    value=plot,
                    source_text=self._find_plot_source(
                        original_transcript
                    ),
                    confidence=0.70,
                )

        return extraction

    # ========================================================
    # DOSAGE SOURCE
    # ========================================================

    @staticmethod
    def _find_dosage_source(
        transcript: str,
    ) -> Optional[str]:

        normalized = VoiceAgent._normalize_marathi_numbers(
            transcript
        )

        normalized = VoiceAgent._normalize_units(
            normalized
        )

        pattern = (
            r"(\d+(?:\.\d+)?)\s*ml"
            r".{0,40}?"
            r"(\d+(?:\.\d+)?)\s*L"
        )

        match = re.search(
            pattern,
            normalized,
            flags=re.IGNORECASE,
        )

        if match:

            return match.group(0).strip()

        pattern = (
            r"\b"
            r"(\d+(?:\.\d+)?)"
            r"\s*"
            r"(ml|L|kg|g)"
            r"\b"
        )

        match = re.search(
            pattern,
            normalized,
            flags=re.IGNORECASE,
        )

        if match:

            return match.group(0).strip()

        return None

    # ========================================================
    # SIMPLE PLOT IDENTIFIER RECOVERY
    # ========================================================

    @staticmethod
    def _extract_simple_plot_identifier(
        transcript: str,
    ) -> Optional[str]:

        # English numeric forms only.
        #
        # Semantic multilingual plot extraction belongs to
        # Gemini. This is merely a conservative fallback.

        patterns = [
            r"\bplot\s*(?:number|no\.?|#)?\s*(\d+)\b",
            r"\bfield\s*(?:number|no\.?|#)?\s*(\d+)\b",
            r"\bplot\s*#\s*(\d+)\b",
        ]

        for pattern in patterns:

            match = re.search(
                pattern,
                transcript,
                flags=re.IGNORECASE,
            )

            if match:

                return f"Plot {match.group(1)}"

        return None

    # ========================================================
    # PLOT SOURCE
    # ========================================================

    @staticmethod
    def _find_plot_source(
        transcript: str,
    ) -> Optional[str]:

        patterns = [
            r"\bplot\s*(?:number|no\.?|#)?\s*\d+\b",
            r"\bfield\s*(?:number|no\.?|#)?\s*\d+\b",
            r"\bplot\s*#\s*\d+\b",
        ]

        for pattern in patterns:

            match = re.search(
                pattern,
                transcript,
                flags=re.IGNORECASE,
            )

            if match:

                return match.group(0).strip()

        return None

    # ========================================================
    # FALLBACK CONFIDENCE
    # ========================================================

    @staticmethod
    def _fallback_confidence(
        *,
        crop: Optional[str],
        action: Optional[str],
        product: Optional[str],
        dosage: Optional[str],
        pest: Optional[str],
    ) -> float:

        values = [
            crop,
            action,
            product,
            dosage,
            pest,
        ]

        known = sum(
            value is not None
            for value in values
        )

        # This is NOT model confidence.
        #
        # It is a conservative completeness score used only
        # when Gemini is unavailable.

        return round(
            min(
                0.85,
                0.30 + known * 0.10,
            ),
            2,
        )

    # ========================================================
    # SEMANTIC / STRUCTURAL VALIDATION
    # ========================================================

    @staticmethod
    def _validate_extraction(
        extraction: VoiceExtractionResult,
        original_transcript: str,
    ) -> VoiceExtractionResult:

        # ----------------------------------------------------
        # Action validation
        # ----------------------------------------------------

        if extraction.action_type.value:

            action = (
                extraction.action_type.value
                .strip()
                .upper()
            )

            if action in SUPPORTED_ACTIONS:

                extraction.action_type.value = action

            else:

                extraction.ambiguous_information.append(
                    "action_type"
                )

                extraction.action_type = ExtractedField(
                    value=None,
                    source_text=(
                        extraction.action_type.source_text
                    ),
                    confidence=0.0,
                )

        # ----------------------------------------------------
        # Validate field confidence
        # ----------------------------------------------------

        fields = [
            "crop",
            "action_type",
            "product_mentioned",
            "dosage",
            "target_pest",
            "plot_name",
            "observation_time",
        ]

        for field_name in fields:

            field = getattr(
                extraction,
                field_name,
            )

            if field is None:

                setattr(
                    extraction,
                    field_name,
                    ExtractedField(),
                )

                continue

            field.confidence = max(
                0.0,
                min(
                    1.0,
                    field.confidence,
                ),
            )

            # If there is no value, there should not be a
            # positive field confidence.

            if field.value is None:

                field.confidence = 0.0

                field.source_text = None

        # ----------------------------------------------------
        # Prevent empty cleaned transcript
        # ----------------------------------------------------

        if not extraction.cleaned_transcript.strip():

            extraction.cleaned_transcript = (
                original_transcript
            )

        # ----------------------------------------------------
        # Overall confidence
        # ----------------------------------------------------

        extraction.confidence = max(
            0.0,
            min(
                1.0,
                extraction.confidence,
            ),
        )

        # ----------------------------------------------------
        # Missing information
        # ----------------------------------------------------

        required_fields = {
            "crop": extraction.crop,
            "action_type": extraction.action_type,
            "product_mentioned": extraction.product_mentioned,
            "dosage": extraction.dosage,
            "target_pest": extraction.target_pest,
            "plot_name": extraction.plot_name,
        }

        # Rebuild missing list to prevent stale values.

        missing = []

        for field_name, field in required_fields.items():

            if (
                field is None
                or field.value is None
            ):

                missing.append(field_name)

        extraction.missing_information = missing

        # ----------------------------------------------------
        # Remove duplicate ambiguity entries
        # ----------------------------------------------------

        extraction.ambiguous_information = list(
            dict.fromkeys(
                extraction.ambiguous_information
            )
        )

        # ----------------------------------------------------
        # Clarification logic
        # ----------------------------------------------------

        if extraction.ambiguous_information:

            extraction.needs_clarification = True

            if not extraction.clarification_question:

                extraction.clarification_question = (
                    "Could you please repeat the unclear "
                    "part of your field observation?"
                )

        # ----------------------------------------------------
        # If clarification is required, ensure question exists.
        # ----------------------------------------------------

        if (
            extraction.needs_clarification
            and not extraction.clarification_question
        ):

            extraction.clarification_question = (
                "Could you please clarify the field observation?"
            )

        return extraction

    # ========================================================
    # API RESPONSE BUILDER
    # ========================================================

    @staticmethod
    def _build_response(
        *,
        request: VoiceLogRequest,
        transcript: str,
        language: str,
        extraction: VoiceExtractionResult,
        extraction_method: str,
    ) -> VoiceLogResponse:

        return VoiceLogResponse(

            raw_transcript=transcript,

            detected_language=language,

            # ------------------------------------------------
            # API keeps the existing flat response contract.
            # ------------------------------------------------

            crop=(
                extraction.crop.value
                if extraction.crop
                else None
            ),

            action_type=(
                extraction.action_type.value
                if extraction.action_type
                else None
            ),

            product_mentioned=(
                extraction.product_mentioned.value
                if extraction.product_mentioned
                else None
            ),

            dosage=(
                extraction.dosage.value
                if extraction.dosage
                else None
            ),

            target_pest=(
                extraction.target_pest.value
                if extraction.target_pest
                else None
            ),

            plot_name=(
                extraction.plot_name.value
                if extraction.plot_name
                else None
            ),

            observation_time=(
                extraction.observation_time.value
                if extraction.observation_time
                else None
            ),

            confidence_score=extraction.confidence,

            missing_information=(
                extraction.missing_information
            ),

            ambiguous_information=(
                extraction.ambiguous_information
            ),

            needs_clarification=(
                extraction.needs_clarification
            ),

            clarification_question=(
                extraction.clarification_question
            ),

            # ------------------------------------------------
            # Rich evidence is preserved here for downstream
            # agents and debugging.
            # ------------------------------------------------

            extracted_entities={

                **extraction.model_dump(),

                "provenance": {

                    "raw_transcript_preserved": True,

                    "extraction_method": (
                        extraction_method
                    ),

                    "field_sources": {

                        "crop": (
                            "LLM"
                            if extraction.crop.source_text
                            else None
                        ),

                        "action_type": (
                            "LLM"
                            if extraction.action_type.source_text
                            else None
                        ),

                        "product_mentioned": (
                            "LLM"
                            if extraction.product_mentioned.source_text
                            else None
                        ),

                        "dosage": (
                            "RULE_RECOVERY"
                            if (
                                extraction.dosage.source_text
                                and extraction.dosage.confidence
                                == 0.75
                            )
                            else (
                                "LLM"
                                if extraction.dosage.source_text
                                else None
                            )
                        ),

                        "target_pest": (
                            "LLM"
                            if extraction.target_pest.source_text
                            else None
                        ),

                        "plot_name": (
                            "RULE_RECOVERY"
                            if (
                                extraction.plot_name.source_text
                                and extraction.plot_name.confidence
                                == 0.70
                            )
                            else (
                                "LLM"
                                if extraction.plot_name.source_text
                                else None
                            )
                        ),

                        "observation_time": (
                            "LLM"
                            if extraction.observation_time.source_text
                            else None
                        ),
                    },
                },
            },
        )


# ============================================================
# GLOBAL AGENT INSTANCE
# ============================================================

voice_agent = VoiceAgent()