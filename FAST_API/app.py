from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

from src.api.routes import router
from src.utils.logging_config import configure_logger
from src.config.settings import get_settings

# Configure logging
logger = configure_logger()

# Get settings
settings = get_settings()

# Create FastAPI app
app = FastAPI(
    title="CureAI API",
    description="Healthcare AI assistant API for diagnosing medical conditions",
    version="1.0.0",
    docs_url=None if settings.environment == "production" else "/docs",
    redoc_url=None if settings.environment == "production" else "/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(router, prefix="/api/v1")

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    host = "0.0.0.0" if settings.environment in ["production", "staging"] else "127.0.0.1"
    
    logger.info(f"Starting CureAI API server on {host}:{port}")
    uvicorn.run(
        "app:app",
        host=host,
        port=port,
        reload=settings.debug,
        log_level="debug" if settings.debug else "info"
    )