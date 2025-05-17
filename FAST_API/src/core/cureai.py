"""
This implementation updates the CureAI class to integrate query checking and 
diagnosis readiness assessment before triggering the diagnosis agent.
"""

from typing import Dict, List, Optional, Any, Tuple
import datetime
import logging
from groq import Groq
import time
from ..database.firestore_agent import FirestoreAgent
from ..utils.conversation import sanitize_conversation_for_llm
from ..services.diagnosis import ReflectionAgent
from ..config.settings import get_settings
from ..services.ready_for_diagnosis import is_conversation_ready_for_diagnosis
from ..services.query_check import classify_health_query

# Instance cache with TTL management
_cureai_instances = {}
_last_access_times = {}

def _clean_expired_instances():
    """Remove expired CureAI instances from cache."""
    settings = get_settings()
    current_time = time.time()
    expired_keys = []
    
    for patient_id, last_access in _last_access_times.items():
        if current_time - last_access > settings.instance_ttl:
            expired_keys.append(patient_id)
    
    for key in expired_keys:
        if key in _cureai_instances:
            del _cureai_instances[key]
        if key in _last_access_times:
            del _last_access_times[key]

async def get_cureai_instance(patient_id: str, groq_client: Optional[Groq] = None, db_agent: Optional[FirestoreAgent] = None, config: Optional[Dict] = None, force_new: bool = False) -> 'CureAI':
    """
    Get an existing CureAI instance or create a new one for the given patient ID.
    
    Args:
        patient_id: Unique identifier for the patient
        groq_client: Optional Groq client to use
        db_agent: Optional database agent to use
        config: Optional configuration dictionary
        force_new: If True, create a new instance even if one exists
        
    Returns:
        CureAI instance
    """
    global _cureai_instances, _last_access_times
    
    # Clean expired instances periodically
    _clean_expired_instances()
    
    # Update last access time for this patient_id
    _last_access_times[patient_id] = time.time()
    
    if patient_id in _cureai_instances and not force_new:
        return _cureai_instances[patient_id]
    
    settings = get_settings()

    if groq_client is None:
        groq_client = Groq(api_key=settings.groq_api_key)
    
    if db_agent is None:
        db_agent = FirestoreAgent(credential_path=settings.firebase_credential_path) 
    
    if config is None:
        config = {
            "model_name": settings.model_name,
            "default_system_prompt": """You are CureAI, a medical AI assistant designed to provide informative health guidance. While you can discuss symptoms, potential conditions, and general health information, you are not a replacement for professional medical care.
Guidelines:
- Focus on gathering relevant medical information through thoughtful questions about symptoms, duration, severity, and medical history.
- When gathering infomation, ASK QUESTIONS ONE BY ONE. ONE AT A TIME.
- Explain medical concepts in clear, accessible language"""
        }
    
    cureai_instance = CureAI(
        groq_client=groq_client,
        patient_id=patient_id,
        db_agent=db_agent,
        config=config
    )
    
    _cureai_instances[patient_id] = cureai_instance
    
    return cureai_instance

class CureAI:
    """
    Core CureAI implementation with Firestore integration for persistent storage.
    """
    def __init__(
        self,
        groq_client: Groq,
        patient_id: str,
        db_agent: FirestoreAgent,
        config: Optional[Dict] = None,
        logger: logging.Logger = None
    ):
        self.groq_client = groq_client
        self.patient_id = patient_id
        self.config = config or {}
        self.logger = logger or logging.getLogger(__name__)
        self.db_agent = db_agent
        self.diagnosis_performed = False
        self.conversation_cache = None
        self.diagnosis_agent = ReflectionAgent(model=self.config.get("model_name", "llama-3.3-70b-versatile"))
        self._initialize_patient()

    
    def _initialize_patient(self):
        """Initialize patient record if it doesn't exist."""
        try:
            patient_data = self.db_agent.get_patient(self.patient_id)
            
            if not patient_data:
                self.db_agent.save_patient(self.patient_id, {"created_at": datetime.datetime.utcnow()})
                self.logger.info(f"Created new patient record: {self.patient_id}")
            
            conversation = self.db_agent.get_conversation(self.patient_id)
            if not conversation:
                # Check if there's medical history in patient data
                medical_history = ""
                if patient_data and "medical_history" in patient_data:
                    medical_history = f"\n\nPatient Medical History: {patient_data['medical_history']}"
                    
                system_prompt = self.config.get("default_system_prompt", "") + medical_history
                self.db_agent.add_message(self.patient_id, "system", system_prompt)
                self.logger.info(f"Initialized conversation for patient: {self.patient_id}")
            else:
                self.conversation_cache = conversation
                self.diagnosis_performed = self._check_diagnosis_in_conversation(conversation)
                        
        except Exception as e:
            self.logger.error(f"Error initializing patient {self.patient_id}: {e}")
            raise
    
    def _check_diagnosis_in_conversation(self, conversation: List[Dict]) -> bool:
        """Check if a diagnosis exists in the conversation history."""
        if not conversation:
            return False
            
        for msg in conversation:
            if msg.get("role") == "assistant" and "diagnosis" in msg.get("content", "").lower():
                return True
        return False

    async def add_user_message(self, message: str) -> 'CureAI':
        """Add a user message to Firestore."""
        if not message:
            raise ValueError("User message cannot be empty")
        
        if not self.db_agent.add_message(self.patient_id, "user", message):
            raise Exception(f"Failed to add user message to database for patient {self.patient_id}")
        
        self.conversation_cache = None
        return self

    async def add_assistant_message(self, message: str) -> 'CureAI':
        """Add an assistant message to Firestore."""
        if not message:
            raise ValueError("Assistant message cannot be empty")
        
        if not self.db_agent.add_message(self.patient_id, "assistant", message):
            raise Exception(f"Failed to add assistant message to database for patient {self.patient_id}")
        
        # Check if this message contains a diagnosis
        if "diagnosis" in message.lower():
            self.diagnosis_performed = True
            
        self.conversation_cache = None
        return self
        
    async def store_diagnosis(self, diagnosis_text: str) -> str:
        """Store the diagnosis in Firestore."""
        timestamp = datetime.datetime.utcnow()
        diagnosis_id = f"diag_{self.patient_id}_{timestamp.strftime('%Y%m%d%H%M%S')}"
        
        diagnosis_record = {
            "diagnosis_text": diagnosis_text,
            "created_at": timestamp,
            "conversation_id": self.patient_id,
            "diagnosis_id": diagnosis_id
        }
        
        self.db_agent.db.collection('diagnoses').document(diagnosis_id).set(diagnosis_record)
        
        patient_update = {
            "latest_diagnosis": {
                "text": diagnosis_text,
                "timestamp": timestamp
            }
        }
        
        self.db_agent.save_patient(self.patient_id, patient_update)
        
        self.logger.info(f"Diagnosis stored for patient {self.patient_id}")
        return diagnosis_id

    async def get_conversation(self):
        """Get the conversation from cache or database."""
        if self.conversation_cache is None:
            self.conversation_cache = self.db_agent.get_conversation(self.patient_id)
        return self.conversation_cache

    async def check_query_for_health_related(self, user_message: str) -> Tuple[bool, float]:
        """Check if the user query is health related."""
        self.logger.info(f"Checking if query is health related: {user_message[:50]}...")
        return classify_health_query(user_message)

    async def check_if_ready_for_diagnosis(self) -> bool:
        """Check if the conversation is ready for diagnosis."""
        conversation = await self.get_conversation()
        self.logger.info(f"Checking if conversation is ready for diagnosis. Conversation length: {len(conversation)}")
        return is_conversation_ready_for_diagnosis(conversation)


    async def get_response(self, user_message: str = None) -> str:
        """Generate a response using the LLM, with added query checking and readiness assessment."""
        try:
            # Get conversation history *before* adding the current user_message
            # This helps determine if the current user_message is a direct answer
            all_messages_before_user_adds = await self.get_conversation()

            if not user_message: # This case is if get_response is called to continue generation without new user input
                self.logger.info("get_response called without new user_message. Generating based on existing history.")
                if not all_messages_before_user_adds:
                    # This should ideally not happen if _initialize_patient ensures a system prompt
                    self.logger.warning("No conversation history found and no user message. Returning generic greeting.")
                    # Add system prompt if missing (defensive)
                    if not any(msg.get("role") == "system" for msg in all_messages_before_user_adds):
                        system_prompt_text = self.config.get("default_system_prompt", "You are a helpful assistant.")
                        await self.add_assistant_message(system_prompt_text) # Or add as system message if appropriate
                        all_messages_before_user_adds = await self.get_conversation()

                    if not all_messages_before_user_adds: # Still empty after trying to add system prompt
                         return "Hello! How can I help you with your health concerns today?"


                clean_conversation_for_continuation = sanitize_conversation_for_llm(all_messages_before_user_adds)
                
                response = self.groq_client.chat.completions.create(
                    messages=clean_conversation_for_continuation,
                    model=self.config.get("model_name", "llama-3.3-70b-versatile"), # Ensure settings are loaded if get_settings() is not available here
                    timeout=get_settings().request_timeout # Assuming get_settings() is accessible or timeout is configured
                ).choices[0].message.content
                
                await self.add_assistant_message(response)
                return response

            # --- Start: Processing a new user_message ---
            self.logger.info(f"Processing new user message for patient {self.patient_id}: '{user_message[:100]}...'")

            # Add the current user message to the conversation history (in Firestore and locally)
            await self.add_user_message(user_message)
            # Fetch the complete history *after* adding the new user message
            all_messages_after_user_adds = await self.get_conversation()
            clean_messages_for_llm = sanitize_conversation_for_llm(all_messages_after_user_adds)
            
            # Determine if the previous message from the assistant was a question
            was_assistant_asking_a_question = False
            if len(all_messages_before_user_adds) > 0: # Check history *before* current user message
                last_message_from_history = all_messages_before_user_adds[-1]
                if last_message_from_history.get("role") == "assistant" and \
                   last_message_from_history.get("content", "").strip().endswith("?"):
                    was_assistant_asking_a_question = True
            
            self.logger.info(f"Was assistant asking a question previously? {was_assistant_asking_a_question}")

            is_health_related_query = True # Assume true if it's a direct answer
            health_query_confidence = 1.0  # Assume high confidence if it's a direct answer

            if not was_assistant_asking_a_question:
                # If it's not a direct answer, classify the user's message
                is_health_related_query, health_query_confidence = await self.check_query_for_health_related(user_message)
                self.logger.info(f"Health query classification: is_health_related={is_health_related_query}, confidence={health_query_confidence}")

            # Handle non-health queries or low-confidence health queries (only if it's NOT a direct answer to a question)
            if not was_assistant_asking_a_question and (not is_health_related_query or health_query_confidence <= 0.7):
                self.logger.info("User message is not health-related or low confidence (and not a direct answer). Redirecting conversation.")
                # For redirection, we only send the system prompt for redirection and the problematic user message.
                # We don't want the LLM to see the previous health conversation if the user is now off-topic.
                redirection_system_prompt = "The user has sent a query that doesn't appear to be health-related or the confidence is low. Politely redirect the conversation back to health topics. Remind them that you're a healthcare assistant designed to discuss medical concerns and conditions. Do not attempt to answer the off-topic query."
                response_content = self.groq_client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": redirection_system_prompt},
                        {"role": "user", "content": user_message} 
                    ],
                    model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                    timeout=get_settings().request_timeout
                ).choices[0].message.content
                
                await self.add_assistant_message(response_content)
                return response_content

            # --- Process health-related queries or direct answers ---
            
            # If a diagnosis has already been performed in this "session" (instance state), 
            # subsequent messages are treated as follow-ups or new, unrelated queries.
            if self.diagnosis_performed:
                self.logger.info("Diagnosis already performed in this session. Generating standard follow-up response.")
                response_content = self.groq_client.chat.completions.create(
                    messages=clean_messages_for_llm, # Full history for context
                    model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                    timeout=get_settings().request_timeout
                ).choices[0].message.content
            else:
                # Check if the conversation (now including the latest user message) is ready for diagnosis
                is_ready_for_diagnosis_check = await self.check_if_ready_for_diagnosis() # Uses full history
                
                if is_ready_for_diagnosis_check:
                    self.logger.info("Conversation deemed ready for diagnosis. Generating diagnosis using ReflectionAgent.")
                    # Use ReflectionAgent to generate the diagnosis based on the full current conversation
                    diagnosis_text = self.diagnosis_agent.run(clean_messages_for_llm, verbose=self.config.get("verbose_reflection", False))
                    
                    self.diagnosis_performed = True # Set flag AFTER successful diagnosis generation
                    await self.store_diagnosis(diagnosis_text) # Store in Firestore
                    
                    # The diagnosis_text from ReflectionAgent should already be well-formatted
                    response_content = (
                        f"{diagnosis_text}\n\n" # diagnosis_text likely already includes "Based on..." and condition list
                        "**DISCLAIMER:** This is a preliminary assessment based on the information you've provided and is not a definitive medical diagnosis. It is essential to consult with a qualified healthcare professional for an accurate diagnosis, personalized medical advice, and treatment. Do not rely solely on this information for medical decisions."
                    )
                else:
                    # Conversation not yet ready for diagnosis, continue gathering information
                    self.logger.info("Conversation not yet ready for diagnosis. Generating standard conversational response.")
                    response_content = self.groq_client.chat.completions.create(
                        messages=clean_messages_for_llm, # Full history
                        model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                        timeout=get_settings().request_timeout
                    ).choices[0].message.content
            
            await self.add_assistant_message(response_content)
            return response_content
            
        except Exception as e:
            self.logger.error(f"Error in get_response for patient {self.patient_id}: {e}", exc_info=True)
            # exc_info=True will log the stack trace
            # Return a generic error message to the user, but log the detailed one.
            # The actual HTTP error sent to client is handled by routes.py's exception handlers.
            raise # Re-raise the exception so routes.py can catch it and return a proper HTTP error
        """Generate a response using the LLM, with added query checking and readiness assessment."""
        try:
            if not user_message:
                conversation = await self.get_conversation()
                clean_conversation = sanitize_conversation_for_llm(conversation)
                
                response = self.groq_client.chat.completions.create(
                    messages=clean_conversation,
                    model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                    timeout=get_settings().request_timeout
                ).choices[0].message.content
                
                await self.add_assistant_message(response)
                return response

            # Step 1: Check if the query is health-related
            is_health_related, confidence = await self.check_query_for_health_related(user_message)
            self.logger.info(f"Query health check: is_health_related={is_health_related}, confidence={confidence}")
            
            # Step 2: Add the user message to the conversation
            await self.add_user_message(user_message)
            all_messages = await self.get_conversation()
            clean_messages = sanitize_conversation_for_llm(all_messages)
            
            # Step 3: Handle non-health queries or redirect back to health topics
            if not is_health_related or confidence <= 0.7:
                self.logger.info("Non-health query detected. Redirecting to health-related conversation.")
                response = self.groq_client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": "The user has sent a query that doesn't appear to be health-related. Politely redirect the conversation back to health topics. Remind them that you're a healthcare assistant designed to discuss medical concerns and conditions."},
                        {"role": "user", "content": user_message}
                    ],
                    model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                    timeout=get_settings().request_timeout
                ).choices[0].message.content
                await self.add_assistant_message(response)
                return response
            
            # Step 4: Process health-related queries
            if is_health_related and confidence > 0.7 and not self.diagnosis_performed:
                # Check if the conversation is ready for diagnosis
                is_ready = await self.check_if_ready_for_diagnosis()
                
                if is_ready:
                    # Perform diagnosis
                    self.logger.info("Conversation is ready for diagnosis. Generating diagnosis...")
                    diagnosis = self.diagnosis_agent.run(sanitize_conversation_for_llm(all_messages), verbose=False)
                    self.diagnosis_performed = True
                    diagnosis_id = await self.store_diagnosis(diagnosis)
                    
                    response = (
                        f"Based on our conversation, I have enough information to provide a preliminary assessment:\n\n{diagnosis}\n\n"
                        "DISCLAIMER: This is not a definitive diagnosis. Please consult a healthcare professional for proper medical advice."
                    )
                else:
                    # Need more information - continue the conversation
                    self.logger.info("Conversation is not yet ready for diagnosis. Asking for more information.")
                    response = self.groq_client.chat.completions.create(
                        messages=clean_messages,
                        model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                        timeout=get_settings().request_timeout
                    ).choices[0].message.content
            else:
                # Standard response for subsequent health queries after diagnosis or non-diagnostic conversations
                response = self.groq_client.chat.completions.create(
                    messages=clean_messages,
                    model=self.config.get("model_name", "llama-3.3-70b-versatile"),
                    timeout=get_settings().request_timeout
                ).choices[0].message.content
            
            await self.add_assistant_message(response)
            return response
            
        except Exception as e:
            self.logger.error(f"Error generating response: {e}")
            raise

    async def reset_chat(self, keep_system_prompt: bool = True) -> None:
        """Reset the conversation in Firestore."""
        try:
            current_convo = await self.get_conversation()
            
            if current_convo:
                # Archive the current conversation
                self.db_agent.update_medical_record(
                    self.patient_id, 
                    {"conversation_history": current_convo}
                )
                
                # Delete the current conversation
                self.db_agent.db.collection('conversations').document(self.patient_id).delete()
            
            # Reset the diagnosis flag
            self.diagnosis_performed = False
            
            # Restore system prompt if needed
            if keep_system_prompt:
                # Check if there's medical history in patient data
                patient_data = self.db_agent.get_patient(self.patient_id)
                medical_history = ""
                if patient_data and "medical_history" in patient_data:
                    medical_history = f"\n\nPatient Medical History: {patient_data['medical_history']}"
                
                system_prompt = self.config.get("default_system_prompt", "") + medical_history
                self.db_agent.add_message(self.patient_id, "system", system_prompt)
                
            # Clear the conversation cache
            self.conversation_cache = None
            
            self.logger.info(f"Chat reset for patient {self.patient_id}")
        except Exception as e:
            self.logger.error(f"Error resetting chat for patient {self.patient_id}: {e}")
            raise

    async def get_conversation_history(self, limit: int = None) -> List[Dict]:
        """Get conversation history with optional limit."""
        messages = await self.get_conversation()
        return messages[-limit:] if limit and messages else messages
    
    async def get_latest_diagnosis(self) -> Optional[Dict]:
        """Get the latest diagnosis for the patient."""
        patient_data = self.db_agent.get_patient(self.patient_id)
        return patient_data.get("latest_diagnosis") if patient_data else None
    
    async def get_all_diagnoses(self) -> List[Dict]:
        """Get all diagnoses for the patient."""
        diagnoses = []
        query = self.db_agent.db.collection('diagnoses').where('conversation_id', '==', self.patient_id).order_by('created_at', direction='DESCENDING')
        
        for doc in query.stream():
            diagnoses.append(doc.to_dict())
            
        return diagnoses