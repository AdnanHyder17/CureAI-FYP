from typing import Optional

class CureAIException(Exception):
    """Base exception for CureAI."""
    def __init__(self, message: str, status_code: int = 500, error_code: Optional[str] = None):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        super().__init__(self.message)

class ModelNotAvailableException(CureAIException):
    """Exception raised when the LLM model is not available."""
    def __init__(self, message: str = "LLM Model not available"):
        super().__init__(message, status_code=503, error_code="MODEL_UNAVAILABLE")

class PatientNotFoundException(CureAIException):
    """Exception raised when a patient is not found."""
    def __init__(self, patient_id: str):
        super().__init__(f"Patient not found: {patient_id}", status_code=404, error_code="PATIENT_NOT_FOUND")

class DatabaseException(CureAIException):
    """Exception raised when a database operation fails."""
    def __init__(self, message: str = "Database operation failed"):
        super().__init__(message, status_code=500, error_code="DATABASE_ERROR")