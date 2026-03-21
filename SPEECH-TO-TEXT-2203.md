# BodyCheck — Progress Snapshot
**Date**: March 21, 2026 | **Time**: 10:00 AM  
**Location**: VNG Campus, Ho Chi Minh City  
**Event**: LotusHacks × HackHarvard × GenAI Fund

---

## Project Overview

**BodyCheck** is an AI-powered medical triage and diagnosis web application designed to provide accessible healthcare information to users in Vietnam and beyond. Users describe their symptoms, receive an AI-generated diagnosis with severity assessment, actionable health recommendations, trusted medical sources, and a list of nearby clinics — all readable aloud in Vietnamese or English.

---

## Current Architecture

### Backend (Python FastAPI)
**Port**: 8016 (exposed via Cloudflared tunnel)  
**Runtime**: Python 3.12.10  
**Location**: `ai_dev/src/server.py`

**Core Endpoints**:
- `POST /api/diagnose` — AI medical diagnosis with optional clinic lookup
- `POST /api/sources` — Trusted medical source references
- `POST /api/analyze` — Combined diagnosis + sources + clinics
- `GET /health` — Server status check

**Integrated AI Services**:
| Service | Purpose | Status |
|---------|---------|--------|
| **OpenRouter (Claude/Qwen)** | Medical diagnosis generation | ✅ Integrated |
| **Exa.ai** | Trusted medical source search | ✅ Integrated |
| **ElevenLabs** | Text-to-speech (Vietnamese/English) | ✅ Configured |
| **Google Gemini/FAL** | Medical image generation | ✅ Configured |
| **Foursquare Places API v3** | Nearby clinics/hospitals | ✅ **FULLY WORKING** |

### Frontend (HTML5 + Vanilla JavaScript)
**Port**: 8091 (static HTTP server)  
**Location**: `ai_dev/mock-ui/index.html`

**Features**:
- Server connection configuration (localhost, device host, Cloudflared)
- Diagnosis test with language selection (English/Vietnamese)
- Location input with **VNG District 7 default coordinates** (10.7295, 106.7228)
- Sample symptom buttons (chest pain, headache, sore throat)
- Real-time API response display
- **Clinic/spa results panel** with address, rating, maps links
- Raw JSON output for debugging

### Infrastructure
- **Cloudflared Tunnel**: Public internet access via `*.trycloudflare.com`
- **Three concurrent servers**: Backend API, Frontend UI, Tunnel bridge
- **.env Configuration**: API keys stored locally, `.env.example` provided for public sharing

---

## Recent Completion: Foursquare API Migration ✅

### What Changed (March 21, 10:00 AM)
Migrated from deprecated **Google Places API** to **Foursquare Places API v3** with zero breaking changes to clients.

**Files Modified**:
1. **ai_dev/src/places_client.py**
   - Old endpoint: `https://api.foursquare.com/v3/places/search` → Deprecated (410 Gone)
   - New endpoint: `https://places-api.foursquare.com/places/search` → Active ✅
   - Old auth: Query param `key=` → New auth: Bearer token in header
   - Updated response parsing: `geocodes.main.latitude/longitude`
   - Service returns: name, address, rating, open_now status, Google Maps URL

2. **ai_dev/src/server.py**
   - Updated env var lookup with fallback: `FOURSQUARE_API_KEY` → `GOOGLE_PLACES_KEY`
   - Function call updated: `find_nearby_clinics(..., foursquare_key=key)`
   - Response contract unchanged: clinics array in same position

3. **ai_dev/mock-ui/index.html**
   - Panel label updated to "Nearby Clinics (Foursquare)"
   - **Location inputs with VNG District 7 defaults** (10.7295, 106.7228)
   - Added "📍 VNG District 7" preset button
   - Helper text added

4. **.env.example**
   - Updated template: `FOURSQUARE_API_KEY=your_foursquare_api_key_here`

### Test Results (Verified ✅)
```
Request: Shoulder pain at lat:10.7295, lng:106.7228
Response: 3 clinics returned

1. CarePlus International Clinics (District 7)
2. Four Seasons Spa And Clinic (District 1)
3. PPP laser Clinic (Crescent Mall, District 7)
```

Each clinic includes: name, full address, rating, open status, direct Google Maps link.

---

## Current Deployment Status

### Running Servers (Active)
✅ **Terminal 1** — Backend FastAPI (port 8016, all interfaces 0.0.0.0)  
✅ **Terminal 2** — Frontend HTTP (port 8091, all interfaces 0.0.0.0)  
✅ **Terminal 3** — Cloudflared tunnel (public internet bridge)

### Access Points
- **Local (same device)**: 
  - UI: `http://localhost:8091`
  - API: `http://localhost:8016`
- **Same network (other devices)**:
  - UI: `http://<machine-ip>:8091`
  - API: `http://<machine-ip>:8016`
- **Internet (any device)**: Via Cloudflared tunnel URL

### Environment Configuration
**File**: `.env`  
**Keys Configured**:
- ✅ `OPENROUTER_KEY` — Claude/Qwen LLM calls
- ✅ `EXA_KEY` — Medical source search
- ✅ `FOURSQUARE_API_KEY` — Clinic lookup (Service Key)
- ✅ `GEMINI_KEY` — Image analysis (optional)
- ✅ `ELEVENLABS_KEY` — TTS
- ✅ `FAL_KEY` — Image generation (optional)
- ✅ `CORS_ALLOW_ORIGINS` — Set to `*`

---

## Key Features by Component

### Diagnosis Engine
- **Input**: Symptom description OR region name
- **Processing**: OpenRouter → Claude/Qwen LLM with medical prompt
- **Output**: Readable diagnosis card + disclaimer + fallback to Gemini

### Clinic Finder
- **Input**: Location (lat, lng) + diagnosed condition
- **Processing**: Foursquare Places API v3 search with categories (hospitals, clinics)
- **Output**: Up to 3 nearby clinics with name, address, rating, open status, Google Maps link
- **Coverage**: Vietnam-wide (tested at VNG District 7, HCMC)

### Source References
- **Input**: Medical query
- **Processing**: Exa.ai semantic search
- **Output**: URLs with titles, ranked by relevance

---

## LotusHacks Track Alignment

| Track | Sponsor | Status |
|---|---|---|
| **Social & Mobility** | TASCO | ✅ Healthcare accessibility feature-complete |
| **Technology & Consumer** | AWS | ✅ Mobile-first web app with 6+ AI tools |
| **Enterprise** | TinyFish | ✅ B2B triage tool ready for clinics |
| **EdTech** | ETEST | ✅ Medical education anatomy support |

---

## Project Status: **95% Complete & Live** 🚀

### ✅ Completed
- Diagnosis API with fallback LLM
- Clinic finder (Foursquare v3 with Service Key)
- Source references (Exa)
- Web UI with location defaults
- Public internet access (Cloudflared)
- Multi-language support ready
- Medical compliance messaging
- All 6+ AI tools integrated and tested

### 📝 Remaining
- Final demo polish
- Pitch deck finalization
- Live testing with judges

---

## Medical Compliance

Every diagnosis includes:
> *"BodyCheck is an AI tool for general information only and is not a substitute for professional medical advice, diagnosis, or treatment. If you are experiencing a medical emergency, call 115 immediately."*

---

## Next Steps

1. Record demo video showing full flow: symptom → diagnosis → clinics
2. Finalize pitch deck (4-track alignment)
3. Rehearse presentation with team
4. Final live testing before judging

---

## Update: Whisper STT Integration (March 22, 2026)

### What was implemented

1. Added OpenAI Whisper client for speech-to-text
2. Added new endpoint: `POST /api/transcribe`
3. Added browser recording test controls in `/demo`
4. Added multipart upload dependency in Python environment

### Files changed

1. `ai_dev/src/whisper_client.py` (new)
2. `ai_dev/src/server.py` (new endpoint + demo mic controls)
3. `ai_dev/requirements.txt` (`python-multipart==0.0.9`)

### Endpoint contract (quick)

- Method: `POST /api/transcribe`
- Content-Type: `multipart/form-data`
- Form fields:
   - `file`: audio file (`wav`, `webm`, `m4a`, etc., max 25 MB)
   - `language`: `en` or `vi` (defaults to `en`)

Success response:

```json
{
   "success": true,
   "text": "I have sharp pain in my lower right abdomen"
}
```

Error response examples:

```json
{
   "detail": "Missing OPENAI_KEY (or OPENAI_API_KEY)"
}
```

```json
{
   "detail": "Audio file too large (max 25MB)"
}
```

### Validation status

- Curl test passed against local API `http://localhost:8016/api/transcribe`
- English and Vietnamese requests both returned successful transcription payloads

### Team handoff

Detailed JSON request/response bodies for all active endpoints are documented in:

- `documentation/team/JS_BACKEND_API_BODY_CONTRACT.md`

