from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional
from backend.app.models.schemas import (
    ValidationRequest,
    ValidationResponse,
    EvidenceItem
)
from backend.app.ai.validation_agent import validation_agent
from backend.app.database.db import db

router = APIRouter(prefix="/validation", tags=["Validation Agent & Evidence Chain"])

@router.post("/verify", response_model=ValidationResponse)
def verify_evidence(request: ValidationRequest):
    result = validation_agent.validate_evidence(request)
    # Update state in DB
    db.update_evidence_status(
        evidence_id=request.evidence_id,
        status=result.status.value,
        score=result.composite_score,
        reasons=result.anomalies
    )
    return result

@router.get("/evidence", response_model=List[Dict[str, Any]])
def list_evidence(farm_id: Optional[str] = None):
    return db.get_all_evidence(farm_id)

@router.get("/evidence/{evidence_id}", response_model=Dict[str, Any])
def get_single_evidence(evidence_id: str):
    ev = db.get_evidence_by_id(evidence_id)
    if not ev:
        raise HTTPException(status_code=404, detail="Evidence not found")
    return ev

@router.post("/evidence/create", response_model=Dict[str, Any])
def create_evidence(item: Dict[str, Any]):
    return db.add_evidence(item)

@router.post("/learning-feedback")
def submit_learning_feedback(feedback: Dict[str, Any]):
    return db.add_feedback(feedback)
