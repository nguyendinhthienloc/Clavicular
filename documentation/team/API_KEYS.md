# API Keys Setup Guide
## Get these done in Hour 0 — everything blocks on Person 3

---

## Quick Links

| Service | Sign-up URL | Who uses it |
|---|---|---|
| OpenRouter | https://openrouter.ai | Person 3 (LLM) |
| fal.ai | https://fal.ai | Person 4 (images) |
| ElevenLabs | https://elevenlabs.io | Person 3 (TTS) + Person 2 (STT) |
| Exa.ai | https://exa.ai | Person 4 (search) |
| Replit | https://replit.com | Person 4 (deploy) |
| Lovable.dev | https://lovable.dev | Person 1 (scaffold) |

---

## OpenRouter

**Cost**: Free credits available at hackathon. Otherwise add $5 (lasts ~1,600 calls).

**Steps**:
1. Go to https://openrouter.ai
2. Sign in with Google
3. Click "Keys" in top nav
4. Click "Create Key" → name it "bodycheck"
5. Copy key (starts with `sk-or-v1-`)
6. Go to "Credits" tab → "Buy Credits" → $5 minimum
   - Ask LotusHacks organisers if OpenRouter is giving sponsor credits

**Models we use**:
- English: `anthropic/claude-3.5-sonnet` (~$0.003 per call)
- Vietnamese: `qwen/qwen-2.5-72b-instruct` (very cheap)
- Fallback: `openai/gpt-4o-mini` (~$0.00015 per call)

**Test your key** (paste in browser console):
```javascript
fetch('https://openrouter.ai/api/v1/models', {
  headers: { 'Authorization': 'Bearer sk-or-v1-YOUR_KEY' }
}).then(r => r.json()).then(d => console.log('Models:', d.data.length));
// Should log: Models: 200+ (or similar number)
```

---

## ElevenLabs

**Cost**: Free tier — 10,000 characters/month TTS + STT access.

**Steps**:
1. Go to https://elevenlabs.io
2. Click "Sign Up" → use Google (fastest)
3. Verify email
4. Click your profile icon (top right)
5. Click "API Keys"
6. Click "+ Create API Key" → name it "bodycheck"
7. Copy the key

**Test your key**:
```javascript
fetch('https://api.elevenlabs.io/v1/user', {
  headers: { 'xi-api-key': 'YOUR_KEY' }
}).then(r => r.json()).then(d => console.log('User:', d.subscription));
// Should log your subscription tier
```

**Voice IDs to try**:
- `EXAVITQu4vr4xnSDxMaL` — Sarah (clear, neutral, works in Vietnamese)
- `21m00Tcm4TlvDq8ikWAM` — Rachel
- Go to https://elevenlabs.io/voice-library to browse and find a voice you like

---

## fal.ai

**Cost**: Free credits at hackathon. Otherwise pay-per-use (~$0.003 per image with Flux Schnell).

**Steps**:
1. Go to https://fal.ai
2. Click "Sign Up" → GitHub login
3. Go to Dashboard (fal.ai/dashboard)
4. Click "API Keys" in sidebar
5. Click "Add key" → name it "bodycheck"
6. Copy the key

**Test your key**:
```javascript
fetch('https://fal.run/fal-ai/flux/schnell', {
  method: 'POST',
  headers: {
    'Authorization': 'Key YOUR_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ prompt: 'A simple red circle', image_size: 'square' })
}).then(r => r.json()).then(d => console.log('Image URL:', d.images?.[0]?.url));
```

---

## Exa.ai

**Cost**: 1,000 free searches/month — more than enough.

**Steps**:
1. Go to https://exa.ai
2. Click "Get API Key" or "Sign Up"
3. Verify email
4. Go to Dashboard → "API Keys"
5. Copy the key

**Test your key**:
```javascript
fetch('https://api.exa.ai/search', {
  method: 'POST',
  headers: {
    'x-api-key': 'YOUR_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ query: 'appendicitis symptoms', num_results: 1 })
}).then(r => r.json()).then(d => console.log('Result:', d.results?.[0]?.title));
```

---

## config.js Template

Create this file locally. DO NOT commit to GitHub.

```javascript
// config.js
// Add this file to .gitignore
window.ENV = {
  OPENROUTER_KEY: 'sk-or-v1-YOUR_KEY_HERE',
  ELEVENLABS_KEY: 'YOUR_ELEVENLABS_KEY_HERE',
  FAL_KEY: 'YOUR_FAL_KEY_HERE',
  EXA_KEY: 'YOUR_EXA_KEY_HERE',
};
```

Add to `.gitignore`:
```
config.js
.env
node_modules/
```

Load in `index.html` as the very first script:
```html
<!DOCTYPE html>
<html>
<head>
  <!-- Load config FIRST before any other scripts -->
  <script src="./config.js"></script>
  ...
```

---

## On Replit (for deploy)

Replit uses Secrets instead of config.js:
1. In your Replit project, click the padlock icon "Secrets"
2. Add each key:
   - Key: `OPENROUTER_KEY`, Value: `sk-or-v1-...`
   - Key: `ELEVENLABS_KEY`, Value: `...`
   - Key: `FAL_KEY`, Value: `...`
   - Key: `EXA_KEY`, Value: `...`
3. Replit exposes secrets as `process.env.KEY_NAME` in Node.js
   For vanilla HTML, you'll need a tiny express server or use Replit's built-in env injection

Simple server.js for Replit:
```javascript
// server.js
const express = require('express');
const app = express();
app.use(express.static('.'));

// Inject env vars into a JS file served dynamically
app.get('/config.js', (req, res) => {
  res.setHeader('Content-Type', 'application/javascript');
  res.send(`window.ENV = {
    OPENROUTER_KEY: '${process.env.OPENROUTER_KEY || ''}',
    ELEVENLABS_KEY: '${process.env.ELEVENLABS_KEY || ''}',
    FAL_KEY: '${process.env.FAL_KEY || ''}',
    EXA_KEY: '${process.env.EXA_KEY || ''}',
  };`);
});

app.listen(3000, () => console.log('BodyCheck running on port 3000'));
```

Install and run:
```bash
npm init -y && npm install express
node server.js
```
