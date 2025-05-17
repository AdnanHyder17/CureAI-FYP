from pydantic import BaseModel, Field, validator
from typing import Optional


class MessageRequest(BaseModel):
    user_message: str = Field(..., description="Message from the user", min_length=1)
    patient_id: str = Field(..., description="Unique identifier for the patient", min_length=1)
    
    @validator('patient_id')
    def validate_patient_id(cls, value):
        value = value.strip()
        if not value:
            raise ValueError("Patient ID cannot be empty")
        return value
    
    @validator('user_message')
    def validate_user_message(cls, value):
        value = value.strip()
        if not value:
            raise ValueError("User message cannot be empty")
        if len(value) > 10000:
            raise ValueError("Message too long (maximum 10,000 characters)")
        return value

# class StartSessionRequest(BaseModel):
#     patient_id: str = Field(..., description="Unique identifier for the patient", min_length=1)
    
#     @validator('patient_id')
#     def validate_patient_id(cls, value):
#         value = value.strip()
#         if not value:
#             raise ValueError("Patient ID cannot be empty")
#         return value
class StartSessionRequest(BaseModel):
    patient_id: str = Field(..., description="Unique identifier for the patient", min_length=1)
    medical_history: Optional[str] = Field(None, description="Patient's medical history")
    
    @validator('patient_id')
    def validate_patient_id(cls, value):
        value = value.strip()
        if not value:
            raise ValueError("Patient ID cannot be empty")
        return value
