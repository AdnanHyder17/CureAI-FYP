import os
from functools import lru_cache

class Settings:
    """Application settings with environment variable configuration."""
    
    def __init__(self):
        self.api_keys = os.getenv("API_KEYS", "").split(",")
        self.firebase_credential_path = os.getenv("FIREBASE_CREDENTIAL_PATH", "cred/my-cureai-firebase-adminsdk.json")
        self.groq_api_key = os.getenv("GROQ_API_KEY", "")
        self.model_name = os.getenv("LLM_MODEL_NAME", "llama-3.3-70b-versatile")
        self.allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
        self.environment = os.getenv("ENVIRONMENT", "development")
        self.debug = self.environment.lower() in ["development", "dev", "local"]
        self.request_timeout = int(os.getenv("REQUEST_TIMEOUT", "60"))
        self.instance_ttl = int(os.getenv("INSTANCE_TTL", "3600"))
        self.cleanup_interval = int(os.getenv("CLEANUP_INTERVAL", "300"))

@lru_cache(maxsize=1)
def get_settings():
    """Cache the settings to avoid reloading environment variables."""
    return Settings()