from fastapi import APIRouter
from backend.app.models.schemas import VoiceLogRequest, VoiceLogResponse
from backend.app.ai.voice_agent import voice_agent

router = APIRouter(prefix="/voice", tags=["Voice Agent & Intent Parser"])

@router.post("/process", response_model=VoiceLogResponse)
def process_voice_note(request: VoiceLogRequest):
    return voice_agent.process_voice_transcript(request)
