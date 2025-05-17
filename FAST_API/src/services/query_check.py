from typing import Optional, Tuple
from pydantic import BaseModel, Field
import json
import logging
from groq import Groq

# Set up logging
logger = logging.getLogger(__name__)

# Define output model
class HealthClassification(BaseModel):
    is_health_related: bool = Field(description="Whether the query is about a personal health issue.")
    confidence_score: float = Field(description="Confidence score between 0 and 1.")

def classify_health_query(user_query: str) -> Tuple[bool, float]:
    """
    Determines if a user query is related to a personal health concern with a confidence score.
    """
    try:
        # Create Groq client
        client = Groq()
        model_name = "llama-3.3-70b-versatile"
        
        completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Determine if the given user query is about a **personal health issue** affecting the user. "
                        "STRICTLY classify only personal health problems like symptoms, medical conditions, treatments, medications, "
                        "or lifestyle advice as 'health-related'. "
                        "EXCLUDE queries about medical coding, AI models, healthcare technology, general medical research, "
                        "or theoretical questions. "
                        "Respond only in JSON format with 'is_health_related' (boolean) and 'confidence_score' (float between 0 and 1)."
                    ),
                },
                {"role": "user", "content": user_query},
            ],
            model=model_name,
            temperature=0,
            response_format={"type": "json_object"},
        )

        # Parse JSON response
        response_data = json.loads(completion.choices[0].message.content)
        classification = HealthClassification(**response_data)
        logger.info(f"Health query classification: {classification.is_health_related}, confidence: {classification.confidence_score}")
        return classification.is_health_related, classification.confidence_score
    
    except json.JSONDecodeError as e:
        logger.error(f"Error parsing JSON response in health query classification: {str(e)}")
        return False, 0.0
    except Exception as e:
        logger.error(f"Error in health query classification: {str(e)}")
        return False, 0.0