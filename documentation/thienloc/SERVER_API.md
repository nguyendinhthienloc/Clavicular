# Person 3 AI Server API Contract

Base URL (local): `http://localhost:8000`

## Health

- Method: `GET`
- Path: `/health`
- Response:

```json
{
  "ok": true,
  "service": "person3-ai-api"
}
```

## Diagnose

- Method: `POST`
- Path: `/api/diagnose`
- Request body:

```json
{
  "user_message": "Chest pressure, left arm pain, severity 9",
  "language": "en"
}
```

- Response body:

```json
{
  "success": true,
  "data": {
    "conditions": [
      {
        "name": "...",
        "likelihood": "High",
        "explanation": "..."
      }
    ],
    "severity": "Low|Medium|High|Emergency",
    "action": "...",
    "home_tips": ["..."],
    "warning_signs": ["..."],
    "disclaimer": "..."
  }
}
```

## Text-to-Speech

- Method: `POST`
- Path: `/api/tts`
- Request body:

```json
{
  "text": "Possible angina. Seek urgent care.",
  "language": "en",
  "output_file": "ai_dev/output/tts.mp3"
}
```

- Response body:

```json
{
  "success": true,
  "audio_path": "ai_dev/output/tts.mp3"
}
```

## Environment variables

- `OPENROUTER_KEY`
- `ELEVENLABS_KEY`

## Medical Sources (Exa)

- Method: `POST`
- Path: `/api/sources`
- Request body:

```json
{
  "query": "appendicitis symptoms",
  "num_results": 5
}
```

- Response body:

```json
{
  "success": true,
  "results": [
    {
      "title": "...",
      "url": "https://www.mayoclinic.org/..."
    }
  ]
}
```

- Notes:
  - Uses includeDomains filter to prefer readable sources:
    - mayoclinic.org
    - webmd.com
    - vinmec.com
    - healthline.com

## Image Generation (fal)

- Method: `POST`
- Path: `/api/image`
- Request body:

```json
{
  "region_name": "lower right abdomen"
}
```

- Response body:

```json
{
  "success": true,
  "image": "data:image/png;base64,/9j/4AAQ..."
}
```

- Notes:
  - Uses Gemini image generation models.
  - Returns base64 data URL suitable for direct `<img src>` assignment.

## Additional environment variables

- `EXA_KEY`
- `GEMINI_KEY`
