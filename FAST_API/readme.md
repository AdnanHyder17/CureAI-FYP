# CureAI API

## Overview

CureAI API is a FastAPI-based backend application designed to function as a healthcare AI assistant for diagnosing medical conditions. It leverages a large language model (LLM) to analyze patient symptoms and provide potential diagnoses. The API also manages patient data and conversation history using Google Firestore.

## Features

* **Health Check**: Verifies the API's health and the availability of its services, including the database and LLM.
* **Session Management**:
    * `Start Session`:  Initiates or continues a patient session.
* **Message Handling**:
    * `Send Message`:  Processes user messages and generates AI responses, including potential diagnoses.
    * `Get Conversation History`: Retrieves the conversation history for a patient.
* **Diagnosis Management**:
    * `Get Diagnoses`: Fetches all diagnoses for a patient.
    * `Get Latest Diagnosis`:  Provides the most recent diagnosis for a patient.

## Technologies Used

* FastAPI:  A modern, fast (high-performance), web framework for building APIs with Python.
* uvicorn:  An ASGI web server.
* Groq:  A large language model used for generating diagnoses and responses.
* Firebase Firestore:  A NoSQL database used to store patient data, messages, and diagnoses.
* pydantic:  Library for data validation and settings management.
* python-dotenv:  Loads environment variables from a `.env` file.
* Other libraries:  colorama, typing-extensions, starlette.

## Setup

### Prerequisites

* Python 3.8+
* pip
* A Google Cloud Platform (GCP) project with Firebase Firestore enabled.
* A Groq API key.

### Installation

1.  Clone the repository.
2.  Create a virtual environment:

    ```bash
    python -m venv venv
    source venv/bin/activate  # On Unix/macOS
    venv\Scripts\activate  # On Windows
    ```
3.  Install the dependencies:

    ```bash
    pip install -r requirements.txt
    ```

### Configuration

1.  **Environment Variables**:
    * Create a `.env` file in the root directory.
    * Add the following variables to the `.env` file:

        ```
        API_KEYS=<your_api_keys>  # Comma-separated list of API keys
        FIREBASE_CREDENTIAL_PATH="path/to/your/firebase_credentials.json" # Path to your Firebase Admin SDK credentials JSON file
        GROQ_API_KEY=<your_groq_api_key>
        LLM_MODEL_NAME="llama-3.3-70b-versatile" # Or your preferred LLM model
        ALLOWED_ORIGINS="*"  # Comma-separated list of allowed origins for CORS
        ENVIRONMENT="development" # or "production", "staging"
        PORT="8000"
        LOG_LEVEL="INFO" #  Logging level
        REQUEST_TIMEOUT="60" # Request timeout in seconds
        INSTANCE_TTL="3600" # TTL for CureAI instances in seconds
        CLEANUP_INTERVAL="300" # Interval for cleaning up CureAI instances in seconds
        ```
    * Ensure to replace the placeholder values with your actual credentials and settings.
2.  **Firebase Credentials**:
    * Download your Firebase Admin SDK credentials JSON file from the Firebase Console.
    * Place it at the path specified in the `FIREBASE_CREDENTIAL_PATH` environment variable (e.g., `cred/cureaitest-firebase-api.json`).

### Running the Application

```bash
python app.py
The API server will start running at http://localhost:8000 (or the host/port specified in your .env file).

API Endpoints
The API is accessible under the /api/v1 prefix.

/api/v1/health : Health check endpoint.
/api/v1/session/start : Start a new session.
/api/v1/chat : Send a message and receive a response.
/api/v1/conversation-history/{patient_id} : Get conversation history.
/api/v1/diagnoses/{patient_id} : Get all diagnoses for a patient.
/api/v1/latest-diagnosis/{patient_id} : Get the latest diagnosis.
Error Handling
The API returns JSON responses with appropriate HTTP status codes.  Exceptions are defined in src/core/exceptions.py. Error responses include a detail message and an optional error_code.

Logging
The application uses the logging module and is configured to log to both the console and a file (logs/cureai_api.log). The log level can be set using the LOG_LEVEL environment variable.

CORS Configuration
The API is configured to allow Cross-Origin Resource Sharing (CORS) as specified by the ALLOWED_ORIGINS environment variable in the .env file.

Production Deployment
For production, ensure the ENVIRONMENT variable is set to "production".
Set docs_url and redoc_url to None in the FastAPI initialization to disable documentation endpoints in production.
Use a production-ready WSGI server like Gunicorn or uvicorn.
Secure your API with appropriate authentication and authorization mechanisms (API keys are used in this project, but consider more robust methods like OAuth 2.0 for production).
Monitor logs and application performance.