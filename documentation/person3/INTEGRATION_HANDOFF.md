# Integration Handoff for Person 1 and Person 2

## Server endpoint

- Base URL on local network (latest build): http://192.168.51.28:8016
- Health check: GET /health
- Diagnose: POST /api/diagnose
- Sources: POST /api/sources
- Image: POST /api/image (currently quota-blocked on Gemini)

## Frontend fetch example

Use this exact code from frontend:

```javascript
const res = await fetch('http://192.168.51.28:8016/api/diagnose', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_message: `Body region: ${region}\nPain type: ${painType}\nDuration: ${duration}\nSeverity: ${severity}\nOther: ${other}`,
    language: language
  })
});

const { data } = await res.json();
// data.conditions, data.severity, data.action, data.home_tips, data.warning_signs, data.disclaimer
```

## Browser console test from teammate laptop

```javascript
const res = await fetch('http://192.168.51.28:8016/api/diagnose', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_message: 'Body region: Head\nSeverity: 3',
    language: 'en'
  })
});

console.log(await res.json());
```

## Sources endpoint example

```javascript
const res = await fetch('http://192.168.51.28:8016/api/sources', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query: 'appendicitis symptoms', num_results: 3 })
});

const data = await res.json();
console.log(data.results);
```

## Curl tests from other computer (PowerShell)

```powershell
# 1) Health
curl.exe -s http://192.168.51.28:8016/health

# 2) Diagnose (OpenRouter text response)
$diag = '{"user_message":"Body region: Chest\nPain type: pressure\nDuration: 30 minutes\nSeverity: 9\nOther: left arm pain","language":"en"}'
Invoke-RestMethod -Uri 'http://192.168.51.28:8016/api/diagnose' -Method Post -ContentType 'application/json' -Body $diag | ConvertTo-Json -Depth 8

# 3) Sources (Exa URL response)
$src = '{"query":"chest pain warning signs","num_results":5}'
Invoke-RestMethod -Uri 'http://192.168.51.28:8016/api/sources' -Method Post -ContentType 'application/json' -Body $src | ConvertTo-Json -Depth 8
```

## Image endpoint note

- Image endpoint is migrated to Gemini and contract is live:
  - `POST /api/image` with `{ "region_name": "lower right abdomen" }`
- Current runtime result is `Image generation failed` due Gemini project quota.
- For demo stability now, integrate diagnose + sources and hide image slot unless `/api/image` returns success.
