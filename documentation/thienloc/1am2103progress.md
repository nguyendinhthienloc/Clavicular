# 1:00 AM 21/03 Progress (Person 3)

## Current status
- UI finalized in [documentation/person3/mock-ui/index.html](documentation/person3/mock-ui/index.html)
- Backend API working on port 8016
- Mock UI working on port 8091
- LAN sharing works for same Wi-Fi testers
- Cloudflared on this Windows setup has certificate/config issues, so LAN is the reliable demo path

## Terminals needed
- LAN demo only: 2 terminals
- Public internet demo via Cloudflared: 3 terminals

### Terminal 1 (Backend)
`d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8016 --reload --log-level debug --access-log`

### Terminal 2 (UI)
`Set-Location documentation/person3/mock-ui; d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m http.server 8091 --bind 0.0.0.0`

### Terminal 3 (Optional Cloudflared)
`cloudflared tunnel --url http://127.0.0.1:8091`

## Share links
- LAN UI: http://192.168.51.28:8091/index.html
- LAN Backend: http://192.168.51.28:8016

## Friend usage
1. Open LAN UI link
2. Base URL field auto-detects host; if needed set manually to http://192.168.51.28:8016
3. Run health/diagnose/sources from UI
