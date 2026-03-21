# Friend Test Guide (Same Wi-Fi)

## Server URL

- Base URL: `http://192.168.51.28:8014`

## 1) Quick health test (browser)

Open this in browser:
- `http://192.168.51.28:8014/health`

Expected:
```json
{"ok":true,"service":"person3-ai-api"}
```

## 2) Diagnose test (browser console)

Paste in browser console:

```javascript
const res = await fetch('http://192.168.51.28:8014/api/diagnose', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_message: "Body region: Chest\nPain type: pressure\nDuration: 30 minutes\nSeverity: 9\nOther: left arm pain",
    language: "en"
  })
});
console.log(await res.json());
```

Expected:
- JSON response with `success: true`
- `data.severity` should be `Emergency`

## 3) Sources test (browser console)

```javascript
const res = await fetch('http://192.168.51.28:8014/api/sources', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query: 'appendicitis symptoms', num_results: 3 })
});
console.log(await res.json());
```

Expected:
- JSON response with `success: true`
- `results` list with readable domains (MayoClinic/WebMD/etc)

## Current note

- Image generation is intentionally deferred right now.
- Focus for integration is `/api/diagnose` and `/api/sources`.
