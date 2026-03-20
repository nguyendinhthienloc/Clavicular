# Person 3 — Finalization Plan
Date: 2026-03-21
Status: 83% complete → targeting 100% demo-ready

---

## Do These Now (blocking)

### 1. Rotate the Exa API key
The key `904401c9-cc10-4f81-8606-7a7ccf898c39` is exposed in PERSON3_AI_2nd_version.md and API_KEYS.md.

1. Go to https://exa.ai → Dashboard → API Keys
2. Delete the current key
3. Create a new key → copy it
4. Update your `.env` / environment with the new key
5. Share the new key with teammates via Discord/Zalo only — not in any file

### 2. Fix the port in INTEGRATION_HANDOFF.md
Your server runs on **8016** but the handoff doc says **8014**. Teammates are hitting the wrong port.

Open `documentation/person3/INTEGRATION_HANDOFF.md` and replace every instance of `8014` with `8016`.

---

## Do These Next (30 min, high impact)

### 3. Run live OpenRouter test
Confirm the real API key works end-to-end, not just dry-run.

```powershell
d:/Hackathon_Clavicular/.venv/Scripts/python.exe ai_dev/src/main.py `
  --message "Body region: Chest, Pain type: pressure, Duration: 30 min, Severity: 9, Other: left arm pain" `
  --language en
```

Expected: JSON with `"severity": "Emergency"`. If not, fix the system prompt.

### 4. Validate all 4 prompt test cases on live API
Run each of these and confirm the severity matches:

| Message | Expected severity |
|---|---|
| `Lower right abdomen, sharp, 6 hours, severity 8, fever and nausea` | High or Emergency |
| `Head, dull, 3 days, severity 4, no other symptoms` | Low |
| `Chest, pressure, 30 min, severity 9, left arm pain` | Emergency |
| `Throat, sore, 2 days, severity 3` | Low |

### 5. Add logging to openrouter_client.py
Silent failures will kill the demo. Add one line to each except block:

```python
# Primary model failure
except Exception as e:
    print(f"[openrouter] primary failed: {e}")

# Fallback model failure
except Exception as e:
    print(f"[openrouter] fallback failed: {e}")
```

### 6. Fix CORS — remove allow_credentials
In `ai_dev/src/server.py`, remove this line from the CORS middleware:

```python
# Remove this line:
allow_credentials=True,
```

Browsers reject wildcard CORS + credentials together. This silently breaks teammate fetches.

### 7. Auto-detect base URL in mock UI
In `documentation/person3/mock-ui/index.html`, add this just before the closing `</script>` tag:

```javascript
const defaultBase = window.location.hostname === 'localhost'
  ? 'http://localhost:8016'
  : `http://${window.location.hostname}:8016`;
document.getElementById('baseUrl').value = defaultBase;
document.getElementById('baseLabel').textContent = defaultBase;
```

Teammates opening the LAN URL will no longer need to edit the field manually.

---

## Verify before calling done

Run through this checklist on your machine, then ask a teammate to run steps 4–6 from their laptop on the same Wi-Fi:

- [ ] `GET http://192.168.51.28:8016/health` returns `{"ok": true}`
- [ ] `POST /api/diagnose` chest pain case returns `"severity": "Emergency"`
- [ ] `POST /api/diagnose` headache case returns `"severity": "Low"` or `"Medium"`
- [ ] `POST /api/diagnose` with `language: "vi"` returns Vietnamese text
- [ ] `POST /api/sources` returns at least 1 result from Mayo/WebMD/Healthline/Vinmec
- [ ] No CORS error in teammate's browser console
- [ ] Exa old key is deleted on exa.ai dashboard
- [ ] Port 8014 no longer appears anywhere in docs

---

## Servers to keep running during integration

Open 2 terminals in workspace root and leave them open:

**Terminal A — API server:**
```powershell
d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8016
```

**Terminal B — Mock UI:**
```powershell
Set-Location documentation/person3/mock-ui
d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m http.server 8091 --bind 0.0.0.0
```

**Optional — public tunnel for remote testers:**
```powershell
cloudflared tunnel --url http://127.0.0.1:8016
```

---

## What you can tell teammates right now

> "My endpoints are live on `http://192.168.51.28:8016`. Use port **8016** (not 8014 — that doc was wrong). Health check, diagnose, and sources are all working. Image and TTS are out of scope. See INTEGRATION_HANDOFF.md for fetch examples."
