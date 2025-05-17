from typing import List, Dict
from pydantic import BaseModel, Field
from groq import Groq
import json
import logging

logger = logging.getLogger(__name__)

# Define output model
class ConversationReadiness(BaseModel):
    is_ready: bool = Field(description="Indicates if the conversation is ready for diagnosis.")

def is_conversation_ready_for_diagnosis(conversation_history: List[Dict]) -> bool:
    """
    Checks if the conversation history is ready for diagnosis using Groq API.

    Criteria:
    - Symptoms must be present.
    - Medical history (if applicable) should be included.
    - Basic patient details like age and gender should be mentioned.
    """
    try:
        # Create Groq client
        client = Groq()
        model_name = "llama-3.3-70b-versatile"
        
        # Clean the conversation history to include only relevant information
        clean_history = []
        for message in conversation_history:
            if message.get("role") in ["user", "assistant"]:
                clean_history.append({
                    "role": message["role"],
                    "content": message["content"]
                })
        
        # Skip if conversation is too short
        if len(clean_history) < 2:
            logger.info("Conversation too short for diagnosis readiness check")
            return False
        
        completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Analyze the given conversation history and determine if it contains enough information "
                        "for a preliminary medical diagnosis. The conversation should include:\n"
                        "1. Clear description of symptoms\n"
                        "2. Duration of symptoms\n"
                        "3. Relevant medical history if applicable\n"
                        "4. Basic patient details like age and gender\n"
                        "5. Any factors that worsen or improve the symptoms\n\n"
                        "Respond in JSON format with 'is_ready' (boolean)."
                    ),
                },
                {"role": "user", "content": json.dumps(clean_history)},
            ],
            model=model_name,
            temperature=0,
            response_format={"type": "json_object"},
        )

        # Parse JSON response
        response_data = json.loads(completion.choices[0].message.content)
        readiness = ConversationReadiness(**response_data)
        logger.info(f"Diagnosis readiness check result: {readiness.is_ready}")
        return readiness.is_ready

    except json.JSONDecodeError as e:
        logger.error(f"Error parsing JSON response in readiness check: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error in readiness check: {str(e)}")
        return False