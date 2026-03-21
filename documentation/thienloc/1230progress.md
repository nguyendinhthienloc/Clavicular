# Person 3 Progress Update (12:30)

Date: 2026-03-21
Owner: Person 3 (AI)

## 1) Runtime Status Right Now
- Backend API: RUNNING on port 8016
- Mock UI server: RUNNING on port 8091
- Cloudflared: installed (ready to tunnel)

## 2) Verified Core API Checks (just tested)
- GET /health: pass
- POST /api/diagnose: pass
- POST /api/sources: pass
- POST /api/echo: pass

## 3) URLs
- Local backend: http://127.0.0.1:8016
- LAN backend (friends on same Wi-Fi): http://192.168.51.28:8016
- Health URL: http://192.168.51.28:8016/health
- Local mock UI: http://127.0.0.1:8091/index.html
- LAN mock UI: http://192.168.51.28:8091/index.html

## 4) Terminal Commands To Host Servers
Open 2 terminals in workspace root.

Terminal A (API):

```powershell
d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8016
```

Terminal B (Mock UI):

```powershell
Set-Location documentation/person3/mock-ui
d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m http.server 8091 --bind 0.0.0.0
```

## 5) Optional Public Sharing (outside your Wi-Fi)
Open another terminal:

```powershell
cloudflared tunnel --url http://127.0.0.1:8016
```

- Share the generated https://<random>.trycloudflare.com URL with remote testers.
- Keep this tunnel terminal open while testing.

## 6) Is Person 3 Work Done?
Status: Core scope is DONE for demo.

Done:
- Diagnosis API live and tested
- Sources API live and tested
- Mock UI improved and shareable on LAN
- Integration-ready endpoints for teammates

Not fully complete (non-blocking for demo):
- Image generation still blocked by provider quota/billing limits (Gemini/OpenAI/fal constraints)
- TTS can remain optional/deferred for stable demo path

## 7) If we need Claude evaluation
Send these files first:
- ai_dev/src/server.py
- ai_dev/src/openrouter_client.py
- ai_dev/src/exa_client.py
- documentation/person3/SERVER_API.md
- documentation/person3/INTEGRATION_HANDOFF.md
- documentation/person3/mock-ui/index.html
- documentation/person3/1230progress.md
