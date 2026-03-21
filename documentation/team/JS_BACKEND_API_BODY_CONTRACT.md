# JS Backend Integration Contract (Person 3 AI API)

This document explains exactly what the JS backend should send and expect from the Python FastAPI server.

## Base URL

Local:
- http://localhost:8016

LAN:
- http://<machine-ip>:8016

Cloudflared:
- Use current tunnel URL

## Response envelope behavior

Most successful endpoints return:

```json
{
  "success": true,
  "...": "endpoint-specific data"
}
```

Errors are returned as FastAPI HTTP errors:

```json
{
  "detail": "Error message"
}
```

Validation errors may return:

```json
{
  "success": false,
  "error": "Invalid request payload",
  "path": "/api/diagnose",
  "hint": "Send a valid JSON object with Content-Type: application/json. Use ai_dev/requests/*.sample.json as templates.",
  "details": []
}
```

## 1) Health

Method and path:
- GET /health

Success output:

```json
{
  "ok": true,
  "service": "person3-ai-api"
}
```

## 2) Echo (quick connectivity test)

Method and path:
- POST /api/echo

Content-Type:
- application/json

Input body:

```json
{
  "text": "hello team"
}
```

Success output:

```json
{
  "success": true,
  "input": "hello team",
  "output": "hello team",
  "length": 10
}
```

## 3) Chat (clinician assistant)

Method and path:
- POST /api/chat

Content-Type:
- application/json

Input body:

```json
{
  "message": "I have fever and sore throat for 2 days",
  "language": "en",
  "session_id": "optional-session-id",
  "history": [
    { "role": "user", "content": "I started coughing yesterday" },
    { "role": "assistant", "content": "Do you have fever or shortness of breath?" }
  ],
  "model": "gpt-4.1-mini",
  "temperature": 0.4
}
```

Field notes:
- message: required string
- language: en or vi
- session_id: optional; server creates one if missing
- history: optional array of { role: user|assistant, content: string }
- model: optional string
- temperature: optional number (0.0 to 1.5)

Success output:

```json
{
  "success": true,
  "reply": "...assistant text...",
  "model": "...model-used...",
  "roleplay": "trained_clinician",
  "session_id": "generated-or-input-session-id",
  "session_turns": 2
}
```

## 4) Diagnose (main diagnosis endpoint)

Method and path:
- POST /api/diagnose

Content-Type:
- application/json

Input body (message-driven):

```json
{
  "user_message": "Sharp lower-right abdominal pain for 3 hours with nausea",
  "language": "en"
}
```

Input body (region-driven):

```json
{
  "region_name": "Rectus_Abdominis_R",
  "language": "en"
}
```

Input body (with coordinates):

```json
{
  "user_message": "Chest pressure and shortness of breath",
  "language": "en",
  "lat": 10.7295,
  "lng": 106.7228
}
```

Field notes:
- One of these must exist: user_message, query, or region_name
- language: en or vi
- Coordinates accepted as:
  - lat/lng
  - latitude/longitude
  - coordinates: { lat, lng } or { latitude, longitude }

Success output:

```json
{
  "success": true,
  "data": {
    "possible_conditions": [],
    "severity": "...",
    "recommendations": [],
    "disclaimer": "..."
  }
}
```

Output shape of data depends on LLM output but is always nested under data.

## 5) Clinics (nearby clinics/hospitals)

Method and path:
- POST /api/clinics

Content-Type:
- application/json

Input body:

```json
{
  "condition_name": "appendicitis",
  "lat": 10.7295,
  "lng": 106.7228,
  "radius_meters": 3000,
  "max_results": 3
}
```

Alternative input keys:
- condition_name or query or user_message (server picks first non-empty)
- lat/lng or latitude/longitude or coordinates object

Success output:

```json
{
  "success": true,
  "condition_name": "appendicitis",
  "origin": {
    "lat": 10.7295,
    "lng": 106.7228
  },
  "results": [
    {
      "name": "Clinic name",
      "address": "...",
      "rating": 4.2,
      "open_now": true,
      "maps_url": "https://maps.google.com/..."
    }
  ]
}
```

## 6) Sources (medical references)

Method and path:
- POST /api/sources

Content-Type:
- application/json

Input body:

```json
{
  "query": "appendicitis symptoms",
  "num_results": 3
}
```

Success output:

```json
{
  "success": true,
  "results": [
    {
      "title": "...",
      "url": "https://...",
      "score": 0.88
    }
  ]
}
```

## 7) Analyze (diagnosis + sources in one call)

Method and path:
- POST /api/analyze

Content-Type:
- application/json

Input body:

```json
{
  "input_text": "Fever, headache, and sore throat for 2 days",
  "language": "en",
  "num_results": 5
}
```

Success output:

```json
{
  "success": true,
  "input": "Fever, headache, and sore throat for 2 days",
  "diagnosis": {},
  "sources": [],
  "sources_error": null
}
```

## 8) Image (medical illustration)

Method and path:
- POST /api/image

Content-Type:
- application/json

Input body:

```json
{
  "region_name": "lower right abdomen"
}
```

Success output:

```json
{
  "success": true,
  "image": "base64-or-image-data",
  "provider": "gemini"
}
```

## 9) Transcribe (Whisper speech-to-text)

Method and path:
- POST /api/transcribe

Content-Type:
- multipart/form-data

Form fields:
- file: required audio file
- language: optional string, en or vi (default en)

Example curl:

```bash
curl -X POST http://localhost:8016/api/transcribe \
  -F "file=@test_audio.wav;type=audio/wav" \
  -F "language=en"
```

Success output:

```json
{
  "success": true,
  "text": "I have sharp pain in my lower right abdomen"
}
```

Known error outputs:

```json
{ "detail": "Missing OPENAI_KEY (or OPENAI_API_KEY)" }
```

```json
{ "detail": "Empty audio file" }
```

```json
{ "detail": "Audio file too large (max 25MB)" }
```

```json
{ "detail": "Transcription failed" }
```

## Suggested JS proxy pattern

If the JS backend is acting as a BFF/proxy, keep endpoint paths and body contracts unchanged when forwarding to Python API. This avoids frontend churn.

Recommended pass-through behavior:
- Keep the same request body keys
- Keep status codes from Python API
- Return the same JSON body (or wrap only if absolutely necessary)

## Source of truth

If this contract and code ever differ, code is source of truth:
- ai_dev/src/server.py
- ai_dev/src/whisper_client.py
