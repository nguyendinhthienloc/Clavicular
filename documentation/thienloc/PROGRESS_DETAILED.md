# Person 3 Progress Report

Date: 2026-03-20
Owner: Person 3 (AI Core)

## Summary

Person 3 AI work is now split into a dedicated Python workspace under `ai_dev`, separate from frontend and backend application folders. Legacy JavaScript AI files were archived.

## What Was Migrated

### Python-only AI workspace
- Added `ai_dev/src/openrouter_client.py`
- Added `ai_dev/src/elevenlabs_client.py`
- Added `ai_dev/src/config.py`
- Added `ai_dev/src/main.py` (CLI)
- Added `ai_dev/requirements.txt`
- Added `ai_dev/README.md`

### Legacy browser AI files archived
- `archive/legacy_js/api/openrouter.js`
- `archive/legacy_js/api/elevenlabs.js`
- `archive/legacy_js/components/diagnosis-card.js`
- `archive/legacy_js/index.html`

## Documentation Organization

- Consolidated docs under `documentation/`
- Person 3 docs under `documentation/person3/`
- Team docs under `documentation/team/`

## Test Status

### Executed and passed
1. Dependency install:
   - `python -m pip install -r ai_dev/requirements.txt`
2. Syntax check:
   - `python -m py_compile ai_dev/src/config.py ai_dev/src/openrouter_client.py ai_dev/src/elevenlabs_client.py ai_dev/src/main.py`
3. End-to-end dry-run:
   - `python ai_dev/src/main.py --message "Chest pressure, left arm pain, severity 9" --language en --dry-run`
   - Result: successful JSON output (fallback path)
4. API server health test (no paid API usage):
   - Started `uvicorn ai_dev.src.server:app` on port `8010`
   - `GET http://127.0.0.1:8010/health` returned 200 with `{"ok": true, "service": "person3-ai-api"}`
5. Next Steps curl diagnosis suite against active port `8000`:
   - Test 1 expected High/Emergency -> actual Emergency
   - Test 2 expected Low -> actual Low
   - Test 3 expected Emergency -> actual Emergency
   - Test 4 expected Low -> actual Low
6. Mock UI prepared for integration testing:
   - `documentation/person3/mock-ui/index.html`

### Not executed yet
- Live OpenRouter API call from Python using real key
- Live ElevenLabs TTS generation from Python using real key (currently returns `Missing ELEVENLABS_KEY or text`)
- Full 4-case prompt quality verification against live model

## Current Deliverable Status

- [x] Dedicated Python AI folder created (`ai_dev`)
- [x] AI logic migrated to Python modules
- [x] CLI workflow implemented for diagnosis and optional TTS
- [x] Local dry-run tests passed
- [ ] Live external API tests passed (OpenRouter, ElevenLabs)
- [ ] Prompt quality validated on all 4 required test cases

## Immediate Next Steps

1. Run one live OpenRouter test from `ai_dev/src/main.py`.
2. Run one live ElevenLabs TTS generation with `--tts`.
3. Validate 4 required prompt cases and tune system prompt if needed.
4. Decide whether to deprecate JS AI files after frontend switches to Python service.

## Current AI Server Runtime

- Entrypoint: `ai_dev/src/server.py`
- Protocol: HTTP JSON (FastAPI)
- Default local endpoints:
   - `GET /health`
   - `POST /api/diagnose`
   - `POST /api/tts`
