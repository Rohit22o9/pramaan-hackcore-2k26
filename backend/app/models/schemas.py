from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from enum import Enum
from datetime import datetime

class EvidenceType(str, Enum):
    VOICE_LOG = "VOICE_LOG"
    CROP_IMAGE = "CROP_IMAGE"
    PRODUCT_SCAN = "PRODUCT_SCAN"
    FIELD_OBSERVATION = "FIELD_OBSERVATION"
    APPLICATION_LOG = "APPLICATION_LOG"

class VerificationStatus(str, Enum):
    PENDING = "PENDING"
    VERIFIED = "VERIFIED"
    FLAGGED = "FLAGGED"
    REJECTED = "REJECTED"

class UserRole(str, Enum):
    FARMER = "FARMER"
    FIELD_AGENT = "FIELD_AGENT"
    BUYER = "BUYER"

# Location & Environment Metadata
class GeoLocation(BaseModel):
    latitude: float
    longitude: float
    accuracy_meters: Optional[float] = 5.0
    field_name: Optional[str] = "Plot North-04"
    village: Optional[str] = "Nashik Rural"

class WeatherSnapshot(BaseModel):
    temperature_c: float
    humidity_percent: float
    wind_speed_kmh: float
    precipitation_prob: float
    condition: str
    spray_suitability_score: float # 0.0 - 1.0 (1.0 = optimal)
    spray_recommendation: str
    apparent_temp_c: Optional[float] = None
    delta_t_c: Optional[float] = None
    dew_point_c: Optional[float] = None
    wind_gusts_kmh: Optional[float] = None
    cloud_cover_percent: Optional[float] = None
    soil_moisture_percent: Optional[float] = None
    location_name: Optional[str] = "Punjab Central Agri-Zone"
    district_name: Optional[str] = "Ludhiana"
    state_name: Optional[str] = "Punjab"
    is_punjab_region: bool = True
    pau_advisory_text: Optional[str] = None


# Evidence Item Model
class EvidenceItem(BaseModel):
    id: str
    farm_id: str
    crop_name: str
    crop_stage: str
    evidence_type: EvidenceType
    timestamp: str
    location: GeoLocation
    weather: Optional[WeatherSnapshot] = None
    title: str
    description: str
    media_url: Optional[str] = None
    audio_transcript: Optional[str] = None
    product_qr: Optional[str] = None
    product_name: Optional[str] = None
    dosage_per_acre: Optional[str] = None
    verification_status: VerificationStatus = VerificationStatus.PENDING
    verification_score: float = 0.0 # 0.0 to 100.0
    verification_hash: Optional[str] = None
    agent_verdicts: Dict[str, Any] = Field(default_factory=dict)
    flag_reasons: List[str] = Field(default_factory=list)

# Voice Parsing Request & Result
class VoiceLogRequest(BaseModel):
    audio_base64: Optional[str] = None
    audio_transcript: Optional[str] = None
    language: str = "hi" # hi, en, mr, te, pa, gu
    farm_id: str = "farm-101"
    latitude: Optional[float] = 19.9975
    longitude: Optional[float] = 73.7898

class VoiceLogResponse(BaseModel):
    raw_transcript: str
    detected_language: str
    crop: Optional[str] = None
    action_type: Optional[str] = None # e.g. "SPRAY", "OBSERVE", "IRRIGATE", "FERTILIZE"
    product_mentioned: Optional[str] = None
    dosage: Optional[str] = None
    target_pest: Optional[str] = None
    plot_name: Optional[str] = None
    confidence_score: float
    extracted_entities: Dict[str, Any]

# Vision Analysis Request & Result
class VisionAnalysisRequest(BaseModel):
    image_base64: Optional[str] = None
    image_url: Optional[str] = None
    crop_type: Optional[str] = "Auto-Detect"
    plot_id: Optional[str] = "plot-01"

class VisionAnalysisResponse(BaseModel):
    crop_detected: str = "Unknown Crop"
    scientific_name: Optional[str] = None
    crop_stage: Optional[str] = "Mature Canopy"
    disease_detected: str
    health_status: Optional[str] = "Diseased" # "Diseased", "Pest Infested", "Nutrient Deficient", "Healthy Crop", "Stressed"
    confidence: float
    severity_level: str # Low, Medium, High, Critical
    pest_count_estimate: int = 0
    affected_percentage: float = 0.0
    symptoms: List[str] = Field(default_factory=list)
    recommended_active_ingredient: str
    organic_alternative: str
    urgency_days: int = 3
    treatment_advice: Optional[str] = None
    prevention_tips: Optional[List[str]] = Field(default_factory=list)


# Validation Agent Models
class ValidationRequest(BaseModel):
    evidence_id: str
    farm_id: str
    evidence_type: EvidenceType
    timestamp: str
    location: GeoLocation
    crop_name: str
    product_data: Optional[Dict[str, Any]] = None
    observation_data: Optional[Dict[str, Any]] = None

class ValidationResponse(BaseModel):
    evidence_id: str
    status: VerificationStatus
    composite_score: float # 0 - 100
    hash_signature: str
    breakdown: Dict[str, float] # geo_match, weather_plausibility, product_authenticity, image_integrity
    explanation: str
    anomalies: List[str]

# Efficacy Tracking Models
class EfficacyRequest(BaseModel):
    farm_id: str
    crop: str
    product_applied: str
    pre_application_evidence_id: str
    post_application_evidence_ids: List[str]

class EfficacyResponse(BaseModel):
    product_applied: str
    recovery_rate_percent: float # e.g. 84.5%
    pest_reduction_percent: float # e.g. 91.0%
    canopy_vitality_index: float # 0 - 1.0 (NDVI proxy)
    efficacy_rating: str # "Outstanding", "Standard", "Underperforming"
    days_elapsed: int
    economic_yield_gain_est_inr: float
    comparative_notes: str

# Weather & Spray Window Models
class WeatherAdvisoryRequest(BaseModel):
    latitude: Optional[float] = 30.9010
    longitude: Optional[float] = 75.8573
    district: Optional[str] = "Ludhiana"
    crop: Optional[str] = "Wheat (Kanak)"
    planned_chemical: Optional[str] = "Propiconazole 25% EC (Tilt)"

class SprayWindowSlot(BaseModel):
    time_window: str
    suitability: str # "OPTIMAL", "MODERATE", "DO_NOT_SPRAY"
    temperature_c: float
    wind_kmh: float
    rain_probability_percent: int
    advisory_reason: str
    delta_t_c: Optional[float] = None
    humidity_percent: Optional[float] = None

class PunjabDistrictInfo(BaseModel):
    id: str
    name: str
    punjabi_name: str
    latitude: float
    longitude: float
    agro_zone: str # Central Plain Zone, Western Zone (Malwa), Majha, Doaba, Undulating (Kandi)
    primary_crops: List[str]
    pau_station: str
    key_pest_risks: List[str]

class WeatherAdvisoryResponse(BaseModel):
    current_weather: WeatherSnapshot
    upcoming_windows: List[SprayWindowSlot]
    pest_pressure_forecast: str
    microclimate_alert: Optional[str] = None
    punjab_agro_zone: Optional[str] = "Central Plain Zone (PAU Ludhiana)"
    delta_t_status: Optional[str] = "OPTIMAL_SPRAY_WINDOW"


# Report Generation Models
class AuditReportRequest(BaseModel):
    farm_id: str
    crop: str
    season: str = "Kharif 2026"
    include_cryptographic_audit: bool = True
    buyer_name: Optional[str] = "ITC Agri-Business"

class AuditReportResponse(BaseModel):
    report_id: str
    farm_name: str
    crop: str
    total_evidence_count: int
    verified_evidence_count: int
    compliance_score_percent: float
    chemical_residue_risk: str # "Very Low (Organic Grade)", "Compliant / MRL Safe", "Borderline"
    sustainability_index: float # 0 - 100
    pdf_download_url: str
    json_manifest_url: str
    blockchain_hash_anchor: str
    generated_at: str

# Buyer Pricing Models
class BuyerPricingRequest(BaseModel):
    crop: str
    quantity_quintals: float
    farm_id: str
    compliance_score: float

class BuyerPricingResponse(BaseModel):
    base_mandi_price_per_qtl: float
    pramaan_verified_premium_per_qtl: float
    total_rate_per_qtl: float
    total_lot_value_inr: float
    purity_grade: str # A+, A, B
    traceability_seal_url: str
    buyer_advantages: List[str]

# Ask Pramaan Chat
class ChatMessage(BaseModel):
    sender: str # "user" or "pramaan_ai"
    text: str
    timestamp: Optional[str] = None
    suggested_actions: Optional[List[str]] = None
    media_url: Optional[str] = None

class ChatQueryRequest(BaseModel):
    message: str
    crop_context: Optional[str] = "Cotton"
    farm_id: Optional[str] = "farm-101"
    language: Optional[str] = "en"

class ChatQueryResponse(BaseModel):
    reply: str
    audio_tts_url: Optional[str] = None
    citations: List[str] = Field(default_factory=list)
    action_chips: List[str] = Field(default_factory=list)
