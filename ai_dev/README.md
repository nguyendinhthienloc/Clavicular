# AI Dev (Python Only)

This folder is dedicated to Person 3 AI development and is intentionally separate from frontend and backend app code.

## What is inside

- `src/openrouter_client.py`: OpenRouter diagnosis logic with fallback model and fallback diagnosis.
- `src/elevenlabs_client.py`: ElevenLabs TTS generation to mp3.
- `src/main.py`: CLI entrypoint for diagnosis and optional TTS.
- `src/server.py`: FastAPI server exposing integration endpoints for other teammates.
- `requirements.txt`: Python dependencies.

## Setup

1. Ensure project root `.env` has at least:
   - `OPENROUTER_KEY=...`
   - `ELEVENLABS_KEY=...`
2. Install deps:
   - `d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m pip install -r ai_dev/requirements.txt`

## Run API server

- Start server:
  - `d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8000`

- Health check:
  - `GET http://localhost:8000/health`

- Diagnose endpoint:
  - `POST http://localhost:8000/api/diagnose`
  - Body:
    - `{ "user_message": "Chest pressure, left arm pain, severity 9", "language": "en" }`

## Stable API smoke tests (recommended for all computers)

Use checked-in JSON templates to avoid shell escaping bugs.

- Diagnose template: `ai_dev/requests/diagnose.sample.json`
- Sources template: `ai_dev/requests/sources.sample.json`

PowerShell (Windows):
- `d:/Hackathon_Clavicular/.venv/Scripts/python.exe ai_dev/scripts/smoke_api.py --base-url http://127.0.0.1:8016`
- or `powershell -ExecutionPolicy Bypass -File ai_dev/scripts/smoke_api.ps1 -BaseUrl http://127.0.0.1:8016`

Cross-platform (Windows/macOS/Linux with Python):
- `python ai_dev/scripts/smoke_api.py --base-url http://127.0.0.1:8016`

Cross-platform curl (Windows/macOS/Linux):
- `curl -s -X POST "http://127.0.0.1:8016/api/diagnose" -H "Content-Type: application/json" --data-binary @ai_dev/requests/diagnose.sample.json`
- `curl -s -X POST "http://127.0.0.1:8016/api/sources" -H "Content-Type: application/json" --data-binary @ai_dev/requests/sources.sample.json`

If Exa key is not configured, skip sources:
- `python ai_dev/scripts/smoke_api.py --base-url http://127.0.0.1:8016 --skip-sources`

- TTS endpoint:
  - `POST http://localhost:8000/api/tts`
  - Body:
    - `{ "text": "Possible angina. Seek urgent care.", "language": "en", "output_file": "ai_dev/output/tts.mp3" }`

## Run diagnosis

- Dry run (no API call):
  - `d:/Hackathon_Clavicular/.venv/Scripts/python.exe ai_dev/src/main.py --message "Chest pressure, left arm pain, severity 9" --language en --dry-run`
- Live run:
  - `d:/Hackathon_Clavicular/.venv/Scripts/python.exe ai_dev/src/main.py --message "Lower right abdomen, sharp pain, fever, nausea" --language en`

## Run with TTS

- `d:/Hackathon_Clavicular/.venv/Scripts/python.exe ai_dev/src/main.py --message "Throat sore for 2 days" --language en --tts --out ai_dev/output/triage.mp3`
