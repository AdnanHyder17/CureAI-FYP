import fastapi
from fastapi.concurrency import run_in_threadpool
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks, Request, status
from fastapi.responses import JSONResponse
import logging
import datetime
import uuid
from typing import Optional
from groq import Groq
from ..core.cureai import get_cureai_instance
from ..core.exceptions import CureAIException, PatientNotFoundException
from ..config.settings import get_settings, Settings
from ..models.requests import MessageRequest, StartSessionRequest
from ..models.responses import (
    PatientResponse, MessageResponse, ConversationHistoryResponse,
    DiagnosesListResponse, DiagnosisResponse, ErrorResponse, HealthResponse
)
from ..database.firestore_agent import get_firestore_agent

from dotenv import load_dotenv

load_dotenv()
# Configure logging
logger = logging.getLogger(__name__)

# Create router
router = APIRouter()

# Health check endpoint
@router.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Check if the API is running and services are available."""
    services = {
        "api": "healthy"
    }
    
    try:
        # Test database connection
        db_agent = get_firestore_agent()
        await run_in_threadpool(lambda: db_agent.db.collection('health_check').document('ping').set({"timestamp": datetime.datetime.utcnow()}))
        services["database"] = "healthy"
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        services["database"] = "unhealthy"
    
    # Test LLM service
    try:
        groq_client = Groq()
        await run_in_threadpool(lambda: groq_client.chat.completions.create(
            messages=[{"role": "user", "content": "health check"}],
            model=get_settings().model_name,
            max_tokens=5
        ))
        services["llm"] = "healthy"
    except Exception as e:
        logger.error(f"LLM health check failed: {e}")
        services["llm"] = "unhealthy"
    
    # Determine overall status
    status = "healthy"
    if "unhealthy" in services.values():
        status = "unhealthy"
    elif "degraded" in services.values():
        status = "degraded"
    
    return HealthResponse(
        status=status,
        timestamp=datetime.datetime.utcnow(),
        services=services
    )

@router.post("/session/start", response_model=PatientResponse, tags=["Session"])
async def start_session(request: StartSessionRequest):
    """Start a new session or continue an existing one for a patient."""
    try:
        # Create a new CureAI instance (force_new=True ensures we get a fresh instance)
        cureai = await get_cureai_instance(request.patient_id, force_new=True)
        
        # Reset the chat to ensure diagnosis_performed is reset to False
        await cureai.reset_chat(keep_system_prompt=False)
        
        # If medical history is provided, update the system prompt
        if request.medical_history:
            # Create an enhanced system prompt with medical history
            enhanced_prompt = cureai.config.get("default_system_prompt", "") + f"\n\nPatient Medical History: {request.medical_history}"
            
            # Add the enhanced system prompt
            cureai.db_agent.add_message(request.patient_id, "system", enhanced_prompt)
            
            # Update patient record with medical history
            cureai.db_agent.update_medical_record(
                request.patient_id,
                {"medical_history": request.medical_history}
            )
        else:
            # Add the default system prompt
            default_prompt = cureai.config.get("default_system_prompt", "")
            cureai.db_agent.add_message(request.patient_id, "system", default_prompt)
        
        # Get patient data including latest diagnosis
        patient_data = await run_in_threadpool(
            lambda: cureai.db_agent.get_patient(request.patient_id)
        )
        
        if not patient_data:
            raise PatientNotFoundException(request.patient_id)
        
        # Format response
        response = PatientResponse(
            patient_id=request.patient_id,
            created_at=patient_data.get("created_at", datetime.datetime.utcnow()),
            latest_diagnosis=None,
            other_info={}
        )
        
        # Add latest diagnosis if available
        if "latest_diagnosis" in patient_data:
            response.latest_diagnosis = DiagnosisResponse(
                text=patient_data["latest_diagnosis"]["text"],
                timestamp=patient_data["latest_diagnosis"]["timestamp"]
            )
        
        return response
    except CureAIException as e:
        logger.error(f"Session start error: {e}")
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error(f"Unexpected error in start_session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/session/reset", response_model=dict, tags=["Session"])
async def reset_session(request: StartSessionRequest, keep_system_prompt: bool = True):
    """Reset a patient's conversation while preserving their record."""
    try:
        cureai = await get_cureai_instance(request.patient_id)
        await cureai.reset_chat(keep_system_prompt)
        
        return {"success": True, "message": "Session reset successfully"}
    except CureAIException as e:
        logger.error(f"Session reset error: {e}")
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error(f"Unexpected error in reset_session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

# Message endpoint
@router.post("/message", response_model=MessageResponse, tags=["Conversation"])
async def send_message(request: MessageRequest, background_tasks: BackgroundTasks):
    """Send a message to CureAI and get a response."""
    try:
        # Get or create CureAI instance
        cureai = await get_cureai_instance(request.patient_id)
        
        # Get response
        response = await cureai.get_response(request.user_message)
        
        # Get latest diagnosis if available
        latest_diagnosis = await cureai.get_latest_diagnosis()
        
        # Create response object
        message_response = MessageResponse(
            response=response,
            patient_id=request.patient_id,
            conversation_id=request.patient_id,
            diagnosis_performed=cureai.diagnosis_performed,
            request_id=str(uuid.uuid4())
        )
        
        # Add latest diagnosis if available
        if latest_diagnosis:
            message_response.latest_diagnosis = DiagnosisResponse(
                text=latest_diagnosis["text"],
                timestamp=latest_diagnosis["timestamp"]
            )
        
        return message_response
    except CureAIException as e:
        logger.error(f"Message error: {e}")
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error(f"Unexpected error in send_message: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

# Conversation history endpoint
@router.get("/conversation/{patient_id}", response_model=ConversationHistoryResponse, tags=["Conversation"])
async def get_conversation_history(patient_id: str, limit: Optional[int] = None):
    """Get conversation history for a patient."""
    try:
        cureai = await get_cureai_instance(patient_id)
        history = await cureai.get_conversation_history(limit)
        
        return ConversationHistoryResponse(
            patient_id=patient_id,
            messages=history or []
        )
    except CureAIException as e:
        logger.error(f"Conversation history error: {e}")
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error(f"Unexpected error in get_conversation_history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

# Diagnoses endpoints
@router.get("/diagnoses/{patient_id}", response_model=DiagnosesListResponse, tags=["Diagnoses"])
async def get_diagnoses(patient_id: str):
    """Get all diagnoses for a patient."""
    try:
        cureai = await get_cureai_instance(patient_id)
        diagnoses = await cureai.get_all_diagnoses()
        
        return DiagnosesListResponse(
            patient_id=patient_id,
            diagnoses=diagnoses or []
        )
    except CureAIException as e:
        logger.error(f"Get diagnoses error: {e}")
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error(f"Unexpected error in get_diagnoses: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/latest-diagnosis/{patient_id}", response_model=Optional[DiagnosisResponse], tags=["Diagnoses"])
async def get_latest_diagnosis(patient_id: str):
    """Get the latest diagnosis for a patient."""
    try:
        cureai = await get_cureai_instance(patient_id)
        diagnosis = await cureai.get_latest_diagnosis()
        
        if not diagnosis:
            return None
        
        return DiagnosisResponse(
            text=diagnosis["text"],
            timestamp=diagnosis["timestamp"]
        )
    except CureAIException as e:
        logger.error(f"Get latest diagnosis error: {e}")
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error(f"Unexpected error in get_latest_diagnosis: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")