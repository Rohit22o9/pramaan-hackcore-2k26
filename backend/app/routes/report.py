import os
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from backend.app.core.config import settings
from backend.app.models.schemas import AuditReportRequest, AuditReportResponse
from backend.app.ai.report_agent import report_agent
from backend.app.database.db import db

router = APIRouter(prefix="/report", tags=["Report Agent & Proof Certificates"])

@router.post("/generate", response_model=AuditReportResponse)
def generate_report(request: AuditReportRequest):
    return report_agent.generate_audit_report(request)

@router.get("/download/{filename}")
def download_pdf(filename: str):
    file_path = settings.DATA_DIR / "reports" / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Report PDF not found")
    return FileResponse(
        path=str(file_path),
        filename=filename,
        media_type="application/pdf"
    )

@router.get("/manifest/{report_id}")
def get_manifest(report_id: str):
    return {
        "report_id": report_id,
        "standard": "PRAMAAN-EVIDENCE-SCHEMA-V2",
        "blockchain_network": "Pramaan Consortium Proof-of-Authority",
        "evidence_chain": db.get_all_evidence()
    }
