# CureAI: AI-Powered Healthcare Assistant

CureAI is a comprehensive healthcare application designed to assist patients with preliminary medical guidance and connect them with doctors. It features a Flutter-based mobile application for user interaction and a Python FastAPI backend that leverages Large Language Models (LLMs) for conversational AI and diagnostic support.

## Table of Contents

1.  [Overview](#overview)
2.  [Features](#features)
    * [Patient Features](#patient-features)
    * [Doctor Features](#doctor-features)
    * [AI Chatbot Features](#ai-chatbot-features)
3.  [Project Structure](#project-structure)
    * [Flutter Frontend](#flutter-frontend)
    * [Python Backend (FastAPI)](#python-backend-fastapi)
4.  [Core Technologies](#core-technologies)
5.  [Setup and Installation](#setup-and-installation)
    * [Prerequisites](#prerequisites)
    * [Firebase Setup](#firebase-setup)
    * [Backend Setup (FastAPI)](#backend-setup-fastapi)
    * [Flutter Frontend Setup](#flutter-frontend-setup)
6.  [Running the Application](#running-the-application)
    * [1. Start the Backend Server](#1-start-the-backend-server)
    * [2. Expose Backend with Ngrok (for AI Chatbot)](#2-expose-backend-with-ngrok-for-ai-chatbot)
    * [3. Configure Flutter App with Ngrok URL](#3-configure-flutter-app-with-ngrok-url)
    * [4. Run the Flutter Application](#4-run-the-flutter-application)
7.  [API Endpoints Overview](#api-endpoints-overview)
8.  [Contributing](#contributing)
9.  [License](#license)

## Overview

CureAI aims to provide users with an intelligent platform for discussing health concerns. Patients can interact with an AI chatbot for initial guidance, get potential diagnostic insights (which are explicitly not a substitute for professional medical advice), and connect with registered doctors for consultations via chat and video calls. Doctors can manage their profiles, availability, and appointments.

## 📸 Some Application Screenshots

<img src="Screen Shots of the Application/Screenshot_20250517_224045.png" width="300" alt="Home Screen"/>
<img src="Screen Shots of the Application/Screenshot_20250517_224231.png" width="300" alt="Doctors"/>
<img src="Screen Shots of the Application/Screenshot_20250517_224412.png" width="300" alt="Chat Screen"/>
<img src="Screen Shots of the Application/Screenshot_20250517_224501.png" width="300" alt="Profile"/>


## Features

### Patient Features
* **Authentication:** Secure signup and login.
* **Profile Management:** View and update personal details.
* **Health Questionnaire:** Comprehensive form to provide medical history and lifestyle information.
* **Doctor Discovery:** Search and filter doctors by specialty, availability, and ratings.
* **Doctor Profiles:** View detailed doctor profiles, including qualifications, experience, and availability.
* **Appointment Booking:** Schedule appointments with doctors based on their availability.
* **Appointment Management:** View upcoming and past appointments; reschedule or cancel.
* **AI Chatbot:** Interact with an AI assistant for health queries and preliminary diagnostic support.
    * Session management (start new, delete previous).
    * Contextual conversation aware of patient's medical history.
    * Diagnosis display with disclaimers.
* **Communication:**
    * Text chat with doctors.
    * Video calls with doctors during scheduled appointments.
* **Home Dashboard:** Carousel, overview of upcoming appointments.

### Doctor Features
* **Authentication:** Secure signup and login.
* **Professional Profile:** Create and manage detailed professional profiles (qualifications, experience, specialty, consultation fees, languages, availability schedule).
* **Dashboard:** Overview of stats (upcoming/completed appointments, patient count), and today's appointments.
* **Appointment Management:** View upcoming and past appointments. (Future: Accept/reschedule/cancel).
* **Patient List:** View a list of distinct patients they have consulted. (Future: View detailed patient history).
* **Communication:**
    * Text chat with patients.
    * Initiate/join video calls with patients for scheduled appointments.
* **Status Management:** Online/offline status and call availability (`available`, `on_call`, `busy`) updated in Firestore.

### AI Chatbot Features (Backend Powered)
* **Natural Language Conversation:** Engages users in a medical dialogue.
* **Contextual Understanding:** Uses patient's provided medical history to inform responses.
* **Health Query Classification:** Identifies if user queries are relevant to personal health issues.
* **Diagnosis Readiness Assessment:** Determines if enough information has been gathered before attempting a diagnosis.
* **Reflective Diagnosis:** Uses an LLM with a generation and reflection step to provide potential diagnoses and medication suggestions (with clear disclaimers).
* **Session Management:** Backend supports starting new sessions (which can reset context) and accessing conversation history for a patient.

## Project Structure

The project is divided into two main parts:

### Flutter Frontend (`CureAI/lib`)
* `main.dart`: App entry point, theme setup, Firebase initialization.
* `firebase_options.dart`: Firebase project configuration for Flutter.
* `theme.dart`: Defines the application's color palette and UI styles.
* **`screens/`**: Contains all the UI screens for different features:
    * Authentication: `splash_screen.dart`, `login_screen.dart`, `signup_screen.dart`, `role_specific_welcome_screen.dart`.
    * Patient: `homeScreen.dart`, `patient_health_questionnaire.dart`, `doctor_list_screen.dart`, `doctor_detail.page.dart`, `ai_chatbot_screen.dart`.
    * Doctor: `doctor_dashboard_screen.dart`, `doctor_professional_details.dart`, `doctor_appointments_screen.dart`, `doctor_patients_list_screen.dart`.
    * Shared/Communication: `profile_screen.dart`, `chat_list_screen.dart`, `individual_chat_screen.dart`, `call_screen.dart`.
* **`services/`**:
    * `chat_service.dart`: Handles Firestore interactions for text chat and WebRTC call signaling.
* **`widgets/`**: Reusable UI components like `custom_textfield.dart`, `loading_indicator.dart`.
* **`models/` (Implicit):** Data models used within the Flutter app (e.g., `ChatMessage`, `ChatSessionMetadata` in `ai_chatbot_screen.dart`).

### Python Backend (FastAPI) (`CureAI/FAST_API/`)
* `app.py`: Main FastAPI application setup, CORS, and uvicorn server configuration.
* **`src/`**:
    * **`api/routes.py`**: Defines all API endpoints (`/health`, `/session/start`, `/message`, etc.).
    * **`core/cureai.py`**: Contains the main `CureAI` class orchestrating AI logic, LLM interaction, and conversation flow.
    * **`core/exceptions.py`**: Custom exception classes for the API.
    * **`database/firestore_agent.py`**: Handles all communication with Firestore (patient data, conversations, diagnoses).
    * **`models/requests.py` & `responses.py`**: Pydantic models for API request validation and response formatting.
    * **`services/`**: Modules for specific AI tasks:
        * `diagnosis.py`: `ReflectionAgent` for generating diagnoses using an iterative approach.
        * `query_check.py`: Classifies if user input is a health-related query.
        * `ready_for_diagnosis.py`: Assesses if a conversation has enough information for a diagnosis.
    * **`utils/`**: Utility modules:
        * `conversation.py`: Sanitizes conversation data for the LLM.
        * `logging_config.py`: Configures application logging.
    * **`config/settings.py`**: Manages application settings loaded from environment variables.
* `requirements.txt`: Lists Python dependencies.
* `.env` (Recommended, not in repo): For storing environment variables like API keys and Firebase credential path.
* `cred/`: Directory to store the Firebase Admin SDK service account key (e.g., `cureai-7da2f-firebase-adminsdk.json`). **Ensure this is in `.gitignore`!**

## Core Technologies

* **Frontend (Mobile App):**
    * Flutter SDK
    * Dart
    * Firebase Auth (Authentication)
    * Cloud Firestore (Realtime Database for chat, appointments, user profiles)
    * Flutter WebRTC (Video/Voice Calls)
    * Provider (State Management)
    * HTTP/Dio (API Communication)
    * `flutter_markdown` (Displaying formatted diagnosis)
* **Backend (API):**
    * Python 3
    * FastAPI (Web Framework)
    * Uvicorn (ASGI Server)
    * Firebase Admin SDK (Python) (Server-side Firebase access)
    * Groq API (For Large Language Model interaction)
    * Pydantic (Data validation and settings management)
    * `python-dotenv` (Environment variable management)
* **Database:** Google Cloud Firestore
* **Cloud Services:**
    * Firebase (Authentication, Firestore, Storage for profile images)
    * Ngrok (For exposing local backend during development)

## Setup and Installation

### Prerequisites
* Flutter SDK (latest stable version recommended)
* Dart SDK (comes with Flutter)
* Python (3.8+ recommended)
* `pip` (Python package installer)
* Firebase Account and Project
* Groq API Key
* Ngrok Account and CLI installed

### Firebase Setup
1.  **Create a Firebase Project:** Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project (e.g., `cureai-7da2f` if you haven't already).
2.  **Register Your Flutter App:**
    * Add an Android app and/or an iOS app to your Firebase project. Follow the instructions to download `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) and place them in the correct directories in your Flutter project.
    * Ensure `firebase_options.dart` is correctly generated and present in your Flutter project (`flutterfire configure` can help).
3.  **Enable Firebase Services:**
    * **Authentication:** Enable Email/Password sign-in.
    * **Firestore Database:** Create a Firestore database. Start in **test mode** for initial development (but secure it with proper rules before production).
    * **Storage:** Enable Firebase Storage for profile images.
4.  **Service Account Key for Backend:**
    * In your Firebase project settings, go to "Service accounts."
    * Generate a new private key and download the JSON file. This will be used by the Python backend.
5.  **Firestore Security Rules:**
    * Update your Firestore security rules. Refer to the [Security Rules section](#security-rules) (or add a dedicated section if needed) for examples covering `users`, `doctors`, `patients`, `appointments`, `chat_rooms`, `calls`, and `aiChatSessions`. *(You'll need to paste the final version of your rules here or link to them)*.

### Backend Setup (FastAPI)

1.  **Clone the Repository (if applicable) or navigate to your `FAST_API` directory.**
2.  **Place Service Account Key:**
    * Create a directory named `cred` inside your `FAST_API` project root.
    * Place the downloaded Firebase service account JSON file (e.g., `your-project-id-firebase-adminsdk.json`) into the `cred/` directory.
3.  **Create a `.env` file** in the `FAST_API` project root with the following content (replace placeholders):
    ```env
    FIREBASE_CREDENTIAL_PATH="cred/your-project-id-firebase-adminsdk.json"
    GROQ_API_KEY="your_actual_groq_api_key"
    LLM_MODEL_NAME="llama3-70b-8192" # Or your preferred Groq model
    ENVIRONMENT="development" 
    # API_KEYS="your_general_api_key_if_needed" 
    # ALLOWED_ORIGINS="*" # For development; restrict in production
    ```
    **Note:** Ensure `your-project-id-firebase-adminsdk.json` matches the name of your service account file.
4.  **Create a Virtual Environment (Recommended):**
    ```bash
    python -m venv venv
    # Activate it:
    # Windows:
    venv\Scripts\activate
    # macOS/Linux:
    source venv/bin/activate
    ```
5.  **Install Python Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
    (Ensure `requirements.txt` includes `fastapi`, `uvicorn`, `firebase-admin`, `groq`, `python-dotenv`, `pydantic`, etc.)

### Flutter Frontend Setup

1.  **Clone the Repository (if applicable) or navigate to your Flutter project directory.**
2.  **Ensure Firebase is Configured:**
    * `google-services.json` should be in `android/app/`.
    * `GoogleService-Info.plist` should be in `ios/Runner/`.
    * `lib/firebase_options.dart` should be present and correct for your Firebase project.
3.  **Get Flutter Packages:**
    ```bash
    flutter pub get
    ```

## Running the Application

To use all features, especially the AI Chatbot, both the backend server and the Flutter app need to be running. Ngrok is used to expose your local backend to the internet so the Flutter app (especially on a physical device) can reach it.

### 1. Start the Backend Server

1.  Open a terminal in your `FAST_API` project directory.
2.  Activate your Python virtual environment (e.g., `venv\Scripts\activate` or `source venv/bin/activate`).
3.  Run the FastAPI application:
    ```bash
    python app.py
    ```
    Or, if you prefer to specify the host and port for Uvicorn directly (matching the default in `app.py` for development):
    ```bash
    python -m uvicorn app:app --host 127.0.0.1 --port 8000 --reload
    ```
    The server should start, typically on `http://127.0.0.1:8000`. Note this address and port.

### 2. Expose Backend with Ngrok (for AI Chatbot)

1.  **Download Ngrok:** If you haven't already, download ngrok from [https://dashboard.ngrok.com/get-started/setup/windows](https://dashboard.ngrok.com/get-started/setup/windows) (or the appropriate link for your OS).
2.  **Authenticate Ngrok (One-time setup):** Follow the instructions on the ngrok website to add your authtoken.
3.  **Run Ngrok:** Open a new terminal and run the following command, replacing `8000` if your FastAPI server is running on a different port:
    ```bash
    ngrok http 127.0.0.1:8000
    ```
    (If your FastAPI app runs on `0.0.0.0:8000`, `ngrok http 8000` is also fine).
4.  **Copy Ngrok URL:** Ngrok will provide a "Forwarding" URL that looks something like `https://<random-string>.ngrok-free.app`. Copy this HTTPS URL.

### 3. Configure Flutter App with Ngrok URL

1.  Open your Flutter project.
2.  Navigate to `lib/screens/ai_chatbot_screen.dart`.
3.  Find the `_apiBaseUrl` variable within the `AIChatService` class (or wherever you've defined it).
4.  Paste the HTTPS URL you copied from ngrok, ensuring it points to your API's base path:
    ```dart
    // In lib/screens/ai_chatbot_screen.dart (inside AIChatService)
    final String _apiBaseUrl = "YOUR_NGROK_HTTPS_URL_HERE/api/v1"; 
    // Example: final String _apiBaseUrl = "[https://5eae-2400-adc1-40d-2f00-5859-b363-cc6b-5441.ngrok-free.app/api/v1](https://5eae-2400-adc1-40d-2f00-5859-b363-cc6b-5441.ngrok-free.app/api/v1)";
    ```

### 4. Run the Flutter Application

1.  Open your Flutter project in your IDE (VS Code, Android Studio).
2.  Select your target device (emulator or physical device).
3.  Run the Flutter app:
    ```bash
    flutter run
    ```
4.  You should now be able to sign up, log in, and use the AI Chatbot feature, which will communicate with your local backend via ngrok.

## API Endpoints Overview

The backend exposes the following main endpoints under the `/api/v1` prefix:

* `GET /health`: Checks the health of the API and its dependent services.
* `POST /session/start`: Initializes or resets a patient's chat session, potentially with medical history.
* `POST /session/reset`: Resets a patient's conversation context on the backend.
* `POST /message`: Sends a patient's message to the AI and receives a response, potentially including a diagnosis.
* `GET /conversation/{patient_id}`: Retrieves conversation history for a patient.
* `GET /diagnoses/{patient_id}`: Retrieves all stored diagnoses for a patient.
* `GET /latest-diagnosis/{patient_id}`: Retrieves the most recent diagnosis for a patient.
