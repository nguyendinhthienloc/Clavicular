# PLAN_PHASE_2 — Person 3
**BodyCheck · LotusHacks 2026 · Phase 2: Integration & Support**
Date: 2026-03-21 | Status: Core done, supporting team to finish line

---

## 1 — Where you stand right now

Your API scope is 100% complete. Both servers are running. Teammates have the correct LAN URL and working fetch examples. Your job in Phase 2 is not to build — it is to keep the infrastructure stable and unblock Person 1, 2, and 4 as they integrate.

| Status | Task |
|---|---|
| DONE | FastAPI server on port 8016 — health, diagnose, sources, echo |
| DONE | Mock UI on port 8091 with plain-language buttons |
| DONE | Integration handoff doc with correct port + curl examples |
| DONE | Auto-detect base URL in mock UI from window.location |
| DONE | Fallback + retry logic — app never crashes on AI failure |
| DONE | Exa API key rotated |
| BLOCKED | Run live OpenRouter test + validate all 4 prompt cases on live key (OPENROUTER_KEY not loaded in current shell) |
| DONE | Add print() logging in openrouter_client.py except blocks |
| DONE | Remove allow_credentials=True from CORS middleware |

---

## 2 — Keep these running at all times

Do not close either terminal until judging is finished. If either crashes, restart immediately.

**Terminal A — backend:**
```powershell
d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8016 --reload --log-level debug --access-log
```

**Terminal B — mock UI:**
```powershell
Set-Location documentation/person3/mock-ui
d:/Hackathon_Clavicular/.venv/Scripts/python.exe -m http.server 8091 --bind 0.0.0.0
```

- LAN UI: `http://192.168.51.28:8091/index.html`
- LAN backend: `http://192.168.51.28:8016`

---

## 3 — Remaining fixes (15 min)

### Fix 1 — Remove allow_credentials from CORS
Browsers reject wildcard CORS + credentials together. Silently breaks teammate fetches.

In `ai_dev/src/server.py`, delete this line:
```python
allow_credentials=True,   # DELETE THIS LINE
```

### Fix 2 — Add logging to openrouter_client.py
Silent failures mean you have no idea why the demo broke during integration.

```python
# Primary model failure
except Exception as e:
    print(f"[openrouter] primary failed: {e}")

# Fallback model failure
except Exception as e:
    print(f"[openrouter] fallback failed: {e}")
```

### Fix 3 — Validate 4 prompt cases on live API
Dry-run passed. Now confirm with the real key:

| Message | Expected severity |
|---|---|
| `Chest, pressure, 30 min, severity 9, left arm pain` | Emergency |
| `Lower right abdomen, sharp, 6 hours, severity 8, fever` | High or Emergency |
| `Head, dull, 3 days, severity 4, no other symptoms` | Low |
| `Throat, sore, 2 days, severity 3` | Low |

Run with:
```powershell
d:/Hackathon_Clavicular/.venv/Scripts/python.exe ai_dev/src/main.py `
  --message "Chest, pressure, 30 min, severity 9, left arm pain" `
  --language en
```

---

## 4 — How to help each teammate

### Person 1 — UI lead
Person 1 needs to call your endpoints and render results into the diagnosis card.

**Send them this fetch snippet:**
```javascript
const res = await fetch('http://192.168.51.28:8016/api/diagnose', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ user_message: msg, language: lang })
});
const { data } = await res.json();
// data.conditions, data.severity, data.action, data.home_tips, data.warning_signs
```

**Debug guide:**
- CORS error in console → confirm you removed `allow_credentials=True`
- `data` is undefined → they need to destructure `{ data }` from the response, not use the raw object
- severity is always `Medium` → fallback is triggering, OpenRouter key is not loaded
- diagnosis card empty → check `data.conditions[0].name` and `data.action` are being read correctly

### Person 2 — form owner
Person 2 needs to map form fields into the `user_message` string your prompt expects.

**Give them this exact template:**
```javascript
const user_message = [
  `Body region: ${region}`,
  `Pain type: ${painType}`,
  `Duration: ${duration}`,
  `Severity: ${severity}`,
  `Other: ${other}`
].join('\n');

window.runDiagnosis(user_message, language);
```

**Debug guide:**
- VI mode returning English → `language` is being passed as `undefined`, not the string `"vi"`
- JSON parse error → model added backticks, but your server already strips these — check the raw response in Network tab
- Form submits but nothing happens → `window.runDiagnosis` is not defined yet, Person 3 global function is not loaded

### Person 4 — deploy
Person 4 needs your server running on Replit for the demo to work outside LAN.

**Give them exactly these three things:**
1. Requirements path: `ai_dev/requirements.txt`
2. Run command: `python -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8016`
3. Replit Secrets to add (via padlock icon, NOT in any file):
   - `OPENROUTER_KEY` = your OpenRouter key
   - `EXA_KEY` = your new rotated Exa key

**Once Replit URL is live:**
- Person 1 and Person 2 must update their fetch base URL from the LAN IP to the Replit URL
- Remind them of this — they will forget

---

## 5 — E2E integration checklist

Run all of these from a teammate laptop on the same Wi-Fi, then again from a phone on mobile data via the Replit URL.

- [ ] `GET http://192.168.51.28:8016/health` returns `{"ok": true}`
- [ ] `POST /api/diagnose` chest pain case returns `"severity": "Emergency"`
- [ ] `POST /api/diagnose` headache case returns `"severity": "Low"` or `"Medium"`
- [ ] `POST /api/diagnose` with `language: "vi"` returns Vietnamese text
- [ ] `POST /api/sources` query: appendicitis returns 1+ result from Mayo/WebMD/Healthline/Vinmec
- [ ] No CORS error in teammate browser DevTools console
- [ ] Full flow: body map → form → diagnose → card renders in under 10 seconds
- [ ] Same full flow via Replit public URL works outside LAN

---

## 6 — Optional improvements (only if team is not blocked)

### Add is_fallback flag to diagnose response
Teammates cannot tell if they got a real AI response or the static fallback. One extra field fixes this:

```python
is_fallback = diagnosis.get("conditions", [{}])[0].get("name") in (
    "Analysis unavailable", "Không thể phân tích"
)
return {"success": True, "data": diagnosis, "is_fallback": is_fallback}
```

Person 1 can then show a subtle warning banner if `is_fallback` is true.

### Cap query length in exa_client.py
Prevents accidental long strings hitting Exa:

```python
"query": query[:300],   # was: query
```

### Prompt tune if severity is wrong
If any live test case returns wrong severity, add explicit examples to `SYSTEM_EN`:

```
Example: Chest pain + left arm pain = Emergency (never High)
Example: Sore throat severity 3 = Low (never Medium)
```

---

## 7 — What to tell the team right now

Paste this in Discord/Zalo:

> My endpoints are live on `http://192.168.51.28:8016` (port **8016** — old 8014 doc was wrong, fixed now). `/health`, `/api/diagnose`, and `/api/sources` all work. Exa key has been rotated — new key coming to you directly. Check `INTEGRATION_HANDOFF.md` for fetch examples. Person 1 and 2: use the fetch snippet in that doc. Person 4: ping me for the API keys to add as Replit Secrets.
