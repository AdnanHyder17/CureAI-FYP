import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from typing import Dict, List, Optional, Any
import os
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)

class FirestoreAgent:
    """A class to manage healthcare data interactions with Firestore."""

    def __init__(self, credential_path: Optional[str] = None):
        """Initialize with Firestore client."""
        if not firebase_admin._apps:
            try:
                if credential_path:
                    cred = credentials.Certificate(credential_path)
                else:
                    cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred)
            except Exception as e:
                logging.error(f"Firebase initialization failed: {e}")
                raise
        self.db = firestore.client()

    # --- Patient Management ---
    def save_patient(self, patient_id: str, patient_data: Dict[str, Any]) -> bool:
        """Create or update a patient profile."""
        try:
            patient_ref = self.db.collection('patients').document(patient_id)
            patient_ref.set(patient_data, merge=True)
            return True
        except Exception as e:
            logging.error(f"Error saving patient {patient_id}: {e}")
            return False

    def get_patient(self, patient_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve patient data by ID."""
        try:
            doc = self.db.collection('patients').document(patient_id).get()
            return doc.to_dict() if doc.exists else None
        except Exception as e:
            logging.error(f"Error fetching patient {patient_id}: {e}")
            return None

    # --- Message Management ---
    def add_message(self, patient_id: str, role: str, content: str) -> bool:
        """Add a message to a patient's conversation."""
        try:
            conversation_ref = self.db.collection('conversations').document(patient_id)
            new_message = {
                "role": role,
                "content": content,
                "timestamp": datetime.utcnow()
            }
            doc = conversation_ref.get()
            if not doc.exists:
                conversation_ref.set({"messages": [new_message], "last_updated": firestore.SERVER_TIMESTAMP})
            else:
                conversation_ref.update({
                    "messages": firestore.ArrayUnion([new_message]), 
                    "last_updated": firestore.SERVER_TIMESTAMP
                })
            return True
        except Exception as e:
            logging.error(f"Error adding message for {patient_id}: {e}")
            return False

    def get_conversation(self, patient_id: str) -> List[Dict[str, Any]]:
        """Retrieve conversation history for a patient."""
        try:
            doc = self.db.collection('conversations').document(patient_id).get()
            return doc.to_dict().get('messages', []) if doc.exists else []
        except Exception as e:
            logging.error(f"Error fetching conversation for {patient_id}: {e}")
            return []

    # --- Medical Records ---
    def update_medical_record(self, patient_id: str, medical_data: Dict[str, Any]) -> bool:
        """Update or create a medical record for a patient."""
        try:
            medical_ref = self.db.collection('medical_records').document(patient_id)
            medical_data = medical_data.copy()
            medical_data['last_updated'] = firestore.SERVER_TIMESTAMP
            medical_ref.set(medical_data, merge=True)
            return True
        except Exception as e:
            logging.error(f"Error updating medical record for {patient_id}: {e}")
            return False

    def update_health_profile(self, patient_id: str, field: str, value: Any, use_array_union: bool = True) -> bool:
        """
        Update a specific field in the patient's health profile.
        If `use_array_union` is True, assumes the field is a list.
        """
        try:
            patient_ref = self.db.collection('patients').document(patient_id)
            if use_array_union:
                patient_ref.update({f"health_profile.{field}": firestore.ArrayUnion([value])})
            else:
                patient_ref.update({f"health_profile.{field}": value})
            return True
        except Exception as e:
            logging.error(f"Error updating health profile for {patient_id}: {e}")
            return False

# --- Helper function ---
def get_firestore_agent(credential_path: Optional[str] = None) -> FirestoreAgent:
    """
    Create and return a FirestoreAgent instance.
    
    Args:
        credential_path: Optional path to the Firebase credentials file.
                         If None, attempts to use environment variables or default credentials.
    
    Returns:
        An initialized FirestoreAgent instance.
    """
    if credential_path is None:
        credential_path = os.environ.get('FIREBASE_CREDENTIALS_PATH', 'cred/cureaitest-firebase-api.json')
    return FirestoreAgent(credential_path)
