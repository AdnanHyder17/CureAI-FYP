from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any
import datetime
from typing_extensions import Literal

class DiagnosisResponse(BaseModel):
    text: str
    timestamp: datetime.datetime

class PatientResponse(BaseModel):
    patient_id: str
    created_at: datetime.datetime
    latest_diagnosis: Optional[DiagnosisResponse] = None
    other_info: Optional[Dict[str, Any]] = None

class MessageResponse(BaseModel):
    response: str
    patient_id: str
    conversation_id: str
    diagnosis_performed: bool = False
    latest_diagnosis: Optional[DiagnosisResponse] = None
    request_id: str = Field(default=None)

class ConversationHistoryResponse(BaseModel):
    patient_id: str
    messages: List[Dict[str, Any]]

class DiagnosesListResponse(BaseModel):
    patient_id: str
    diagnoses: List[Dict[str, Any]]

class ErrorResponse(BaseModel):
    detail: str
    error_code: Optional[str] = None
    timestamp: datetime.datetime = Field(default_factory=datetime.datetime.utcnow)
    request_id: Optional[str] = None

class HealthResponse(BaseModel):
    status: Literal["healthy", "degraded", "unhealthy"]
    timestamp: datetime.datetime
    version: str = "1.0.0"
    services: Dict[str, str]