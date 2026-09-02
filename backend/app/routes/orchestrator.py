from fastapi import APIRouter
from backend.app.models.schemas import ChatQueryRequest, ChatQueryResponse
from backend.app.ai.orchestrator import orchestrator_agent

router = APIRouter(prefix="/orchestrator", tags=["Orchestrator & Assistant"])

@router.post("/chat", response_model=ChatQueryResponse)
def ask_pramaan_chat(request: ChatQueryRequest):
    return orchestrator_agent.handle_chat_query(request)
