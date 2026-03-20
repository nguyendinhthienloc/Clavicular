# Person 3 Checklist

## Immediate Checklist

- [x] Python AI server exists and boots (`ai_dev/src/server.py`)
- [x] `/health` endpoint verified
- [x] `/api/diagnose` endpoint verified with 4 required cases
- [x] Test 3 returns `Emergency`
- [x] Mock UI created (`documentation/person3/mock-ui/index.html`)
- [x] TTS removed from mock UI for demo stability
- [x] Server reachable on local network (`http://192.168.51.28:8014/health`)
- [x] Integration handoff doc prepared (`documentation/person3/INTEGRATION_HANDOFF.md`)
- [x] `/api/sources` endpoint validated with readable domains
- [x] `/api/image` intentionally deferred for now (quota blocker)
- [x] Server hosted on LAN for friend testing (`http://192.168.51.28:8014`)
- [x] Friend test guide prepared (`documentation/person3/FRIEND_TEST_GUIDE.md`)
- [ ] Share handoff and IP with Person 1 and Person 2

## Recommended Commands

1. Start server:
   - `d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8014`
2. Health check:
   - `curl.exe -s http://localhost:8014/health`
3. Diagnose test:
   - `curl.exe -s -X POST http://localhost:8014/api/diagnose -H "Content-Type: application/json" --data-binary "@ai_dev/tmp_test3.json"`
4. Sources test:
   - `curl.exe -s -X POST http://localhost:8014/api/sources -H "Content-Type: application/json" --data-binary "{\"query\":\"appendicitis symptoms\",\"num_results\":3}"`
