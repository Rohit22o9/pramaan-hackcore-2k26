"""
Automated Verification Suite for Google ADK (Agent Development Kit v2.8.0)
Testing Multi-Agent Orchestration, Tools, and Agent Registries in Pramaan.
"""

import unittest
import google.adk as adk
from backend.app.ai.adk_orchestrator import (
    pramaan_adk_master,
    adk_weather_agent,
    adk_validation_agent,
    adk_voice_agent,
    adk_efficacy_agent,
    get_google_adk_system_info,
    fetch_live_weather_tool,
    verify_evidence_5layer_tool,
    parse_multilingual_voice_tool,
    compute_recovery_efficacy_tool,
)


class TestGoogleADKIntegration(unittest.TestCase):
    def test_google_adk_installed_and_version(self):
        """Proof 1: Google ADK library is imported and verified."""
        self.assertTrue(hasattr(adk, "Agent"), "google.adk.Agent must be available")
        self.assertTrue(hasattr(adk, "Workflow"), "google.adk.Workflow must be available")
        self.assertTrue(hasattr(adk, "Runner"), "google.adk.Runner must be available")
        self.assertTrue(hasattr(adk, "Context"), "google.adk.Context must be available")
        print(f"\n[PROOF 1] Google ADK Version: {adk.__version__}")

    def test_adk_master_and_subagents_hierarchy(self):
        """Proof 2: Google ADK Multi-Agent hierarchy is properly structured."""
        info = get_google_adk_system_info()
        self.assertEqual(info["framework"], "Google ADK (Agent Development Kit)")
        self.assertEqual(info["master_agent"], "PramaanMasterOrchestrator")
        self.assertEqual(info["sub_agents_count"], 4)
        self.assertIn("PramaanWeatherAgent", info["registered_sub_agents"])
        self.assertIn("PramaanValidationAgent", info["registered_sub_agents"])
        self.assertIn("PramaanVoiceAgent", info["registered_sub_agents"])
        self.assertIn("PramaanEfficacyAgent", info["registered_sub_agents"])
        print(f"[PROOF 2] Google ADK Registered Sub-Agents: {info['registered_sub_agents']}")

    def test_adk_weather_tool_execution(self):
        """Proof 3: Google ADK Tool execution for real-time Punjab weather & Delta-T."""
        result = fetch_live_weather_tool(district="Bathinda", crop="Bt Cotton")
        self.assertEqual(result["status"], "SUCCESS")
        self.assertEqual(result["framework"], "Google ADK (Agent Development Kit v2.8.0)")
        self.assertEqual(result["district"], "Bathinda")
        self.assertIn("temperature_c", result)
        self.assertIn("delta_t_c", result)
        print(f"[PROOF 3] ADK Weather Tool Result: {result['district']} -> Temp: {result['temperature_c']}C, Delta-T: {result['delta_t_c']}C ({result['delta_t_status']})")

    def test_adk_validation_tool_execution(self):
        """Proof 4: Google ADK Tool execution for 5-layer verification & SHA-256 seal."""
        result = verify_evidence_5layer_tool(
            farm_id="farm-104",
            crop_name="Wheat (PBW 826)",
            product_name="Tilt 25% EC",
            dosage_per_acre="200 ml in 200L Water",
        )
        self.assertEqual(result["status"], "SUCCESS")
        self.assertEqual(result["verification_status"], "VERIFIED")
        self.assertIsNotNone(result["sha256_hash"])
        self.assertEqual(len(result["sha256_hash"]), 64)
        print(f"[PROOF 4] ADK 5-Layer Verification Tool SHA-256 Seal: {result['sha256_hash'][:24]}... (Score: {result['verification_score']}%)")

    def test_adk_voice_tool_execution(self):
        """Proof 5: Google ADK Tool execution for Punjabi voice NLU parsing."""
        punjabi_voice = "ਮੈਂ ਪਲਾਟ ਇੱਕ ਵਿੱਚ ਕਣਕ ਲਈ 200 ਐਮ ਐਲ ਟਿਲਟ ਸਪਰੇਅ ਕਰ ਦਿੱਤੀ ਹੈ"
        result = parse_multilingual_voice_tool(punjabi_voice, language="pa")
        self.assertEqual(result["status"], "SUCCESS")
        entities = result["parsed_entities"]
        self.assertEqual(entities["action_type"], "SPRAY")
        print(f"[PROOF 5] ADK Multilingual Voice Tool Extracted: Product='{entities['product_mentioned']}', Dose='{entities['dosage']}'")


if __name__ == "__main__":
    unittest.main()
