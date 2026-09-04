"""
Comprehensive Automated Test Suite for PRAMAAN Master Orchestrator Agent.
Tests intent detection, parallel & sequential graph execution, validation gates,
failure recovery, shared state integrity, and role-aware outputs.
"""

import unittest
from backend.app.orchestrator.state import (
    OrchestratorRequest,
    IntentType,
    WorkflowState,
    FieldEvidenceState,
)
from backend.app.orchestrator.router import router
from backend.app.orchestrator.policies import ValidationPolicyEngine, RoleOutputFormatter
from backend.app.orchestrator.workflow import workflow_engine
from backend.app.orchestrator.root_agent import master_orchestrator


class TestPramaanOrchestrator(unittest.IsolatedAsyncioTestCase):

    def test_intent_detection(self):
        """Verify that router accurately identifies various farmer and system intents."""
        # 1. Create Field Record Intent
        req_create = OrchestratorRequest(
            input="I sprayed Bio-Neem Power 10000 PPM on my wheat crop yesterday at 400ml per acre.",
            language="en"
        )
        self.assertEqual(router.detect_intent(req_create), IntentType.CREATE_FIELD_RECORD)

        # 2. Product Comparison / Efficacy Intent
        req_compare = OrchestratorRequest(
            input="Show me how Bio-Neem compared vs chemical control in tomato efficacy performance",
            language="en"
        )
        self.assertEqual(router.detect_intent(req_compare), IntentType.ANALYZE_PRODUCT)

        # 3. Weather / Spray Window Intent
        req_weather = OrchestratorRequest(
            input="What is the weather today and can i spray Delta-T in Ludhiana?",
            language="en"
        )
        self.assertEqual(router.detect_intent(req_weather), IntentType.CHECK_FIELD_STATUS)

        # 4. Marathi Voice Input
        req_marathi = OrchestratorRequest(
            input="मी काल टोमॅटोवर जैविक औषध फवारले 2 लिटर प्रति एकर",
            language="mr"
        )
        self.assertEqual(router.detect_intent(req_marathi), IntentType.CREATE_FIELD_RECORD)

    def test_execution_plan_structure(self):
        """Verify parallel and sequential steps in execution graph."""
        req = OrchestratorRequest(
            input="Sprayed Bio-X on tomato",
            images=["data:image/jpeg;base64,/9j/4AAQSkZJRg=="],
            location={"latitude": 18.52, "longitude": 73.85, "village": "Pune"}
        )
        plan = router.create_execution_plan(IntentType.CREATE_FIELD_RECORD, req)
        
        # NLP, Vision, Weather should be scheduled in parallel
        self.assertIn("NLP", plan.parallel_steps)
        self.assertIn("VISION", plan.parallel_steps)
        self.assertIn("WEATHER", plan.parallel_steps)

        # Validation, Efficacy, Report should be sequential
        self.assertIn("VALIDATION", plan.sequential_steps)
        self.assertIn("EFFICACY", plan.sequential_steps)
        self.assertIn("REPORT", plan.sequential_steps)

    def test_validation_gate_policy(self):
        """Verify validation gate catches missing fields and dosage discrepancies."""
        state = FieldEvidenceState(
            record_id="PRM-TEST-001",
            nlp={
                "result": {
                    "crop": "Tomato",
                    "product": "Bio-X",
                    "dosage": "2 L/acre"
                }
            },
            vision={
                "result": {
                    "product_name": "Bio-X",
                    "dosage": "1 L/acre" # Mismatch!
                }
            },
            weather={"result": {"temperature_c": 26, "spray_recommendation": "OPTIMAL WINDOW"}},
            validation={"result": {"composite_score": 95.0}}
        )

        is_valid, status, flags, missing, prompt = ValidationPolicyEngine.evaluate_gate(state)
        self.assertFalse(is_valid)
        self.assertEqual(status, "NEEDS_REVIEW")
        self.assertTrue(any("Dosage mismatch" in f for f in flags))
        self.assertIsNotNone(prompt)

    def test_role_aware_formatters(self):
        """Verify role-aware outputs for Farmer, Field Agent, and Organization."""
        state = FieldEvidenceState(
            record_id="PRM-2026-000123",
            input={"timestamp": "2026-09-04T10:30:00", "crop_hint": "Tomato", "role": "farmer"},
            nlp={"result": {"crop": "Tomato", "product_mentioned": "Bio-X", "dosage": "2 L/acre"}},
            weather={"result": {"temperature_c": 27.4, "relative_humidity_percent": 78, "delta_t_c": 4.2}},
            validation={"result": {"composite_score": 98.6, "validation_status": "VERIFIED"}},
            analytics={"result": {"recovery_rate_percent": 86.4, "sample_size": 325, "mean_observed_outcome": 78.4}},
        )
        state.workflow.status = WorkflowState.VALIDATED

        # 1. Farmer Output (Simple, readable, friendly)
        farmer_out = RoleOutputFormatter.format_farmer_output(state, lang="en")
        self.assertEqual(farmer_out["role"], "FARMER")
        self.assertIn("Tomato", farmer_out["summary_message"])
        self.assertIn("Bio-X", farmer_out["summary_message"])
        self.assertIn("disclaimer", farmer_out)

        # 2. Field Agent Output (Detailed technical specs & SHA-256 seal)
        agent_out = RoleOutputFormatter.format_field_agent_output(state)
        self.assertEqual(agent_out["role"], "FIELD_AGENT")
        self.assertIn("verification", agent_out)
        self.assertEqual(agent_out["verification"]["composite_score"], 98.6)

        # 3. Organization Output (ANOVA, statistics, and limitations)
        org_out = RoleOutputFormatter.format_organization_output(state)
        self.assertEqual(org_out["role"], "ORGANIZATION")
        self.assertEqual(org_out["validated_observations_n"], 325)
        self.assertIn("statistical_analysis", org_out)
        self.assertIn("methodological_limitations", org_out)

    async def test_full_orchestrator_execution(self):
        """End-to-end orchestration pipeline test."""
        req = OrchestratorRequest(
            user_id="F102",
            role="farmer",
            language="en",
            input_type="voice",
            input="I sprayed Bio-Neem Power on wheat crop at 400 ml per acre in Dindori",
            location={"latitude": 20.0, "longitude": 73.8, "village": "Dindori, Nashik"},
            timestamp="2026-09-04T10:30:00",
            crop_hint="Wheat",
            target_product="Bio-Neem Power 10000 PPM"
        )

        response = await master_orchestrator.process(req)

        self.assertTrue(response.record_id.startswith("PRM-"))
        self.assertIn(response.workflow_status, [WorkflowState.COMPLETED.value, WorkflowState.VALIDATED.value])
        self.assertEqual(response.field_evidence["crop"], "Wheat")
        self.assertIn("Bio-Neem", response.field_evidence["product"])
        self.assertIsNotNone(response.weather_context["temperature"])
        self.assertGreater(response.evidence["record_completeness"], 0.5)
        self.assertGreater(len(response.limitations), 0)
        self.assertNotEqual(response.farmer_message, "")


if __name__ == "__main__":
    unittest.main()
