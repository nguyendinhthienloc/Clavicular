# Person 3 — AI Core
## OpenRouter (Claude) + ElevenLabs TTS + config.js

You own the brain of the app. Two tasks: make Claude return a diagnosis,
make ElevenLabs read it aloud. Everything else is secondary.

---

## Your Hours

```
Hour 0–1    Collect all API keys → put in config.js → share with team
Hour 1–2    Test OpenRouter in browser console (raw fetch, no code yet)
Hour 5–10   Write openrouter.js — prompt, fetch, parse JSON, render card
Hour 10–12  Write elevenlabs.js — TTS reads diagnosis aloud
Hour 20–24  Integration + fixing bugs with the team
```

---

## Hour 0: API Keys

Do this before anything else. The whole team is blocked without keys.

### 1. OpenRouter
1. Go to **openrouter.ai**
2. Sign in with Google
3. Click **Keys** → Create Key → copy it (`sk-or-v1-...`)
4. Click **Credits** → add $5 (or ask organizers for sponsor credits)

### 2. ElevenLabs
1. Go to **elevenlabs.io**
2. Sign up free (no credit card)
3. Profile icon → **API Keys** → Create → copy it

### 3. fal.ai and Exa.ai (collect for Person 4)
- **fal.ai** → sign up → Dashboard → API Keys → copy
- **exa.ai** → sign up → Dashboard → API Keys → copy
  - Your Exa key: `904401c9-cc10-4f81-8606-7a7ccf898c39` (already have this)

### Create config.js
```javascript
// config.js — NEVER commit this file
window.ENV = {
  OPENROUTER_KEY: 'sk-or-v1-YOUR_KEY',
  ELEVENLABS_KEY: 'YOUR_KEY',
  FAL_KEY: 'YOUR_KEY',
  EXA_KEY: '904401c9-cc10-4f81-8606-7a7ccf898c39',
};
```

Add to `.gitignore`:
```
config.js
```

Load it as the **first** script in `index.html`:
```html
<script src="./config.js"></script>
```

Share keys with the team via Discord/Zalo. Do NOT put them in the repo.

---

## Hour 1–2: Test OpenRouter First

Before writing any real code, paste this in the browser console to confirm
the key works:

```javascript
const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${window.ENV.OPENROUTER_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    model: 'anthropic/claude-3.5-sonnet',
    messages: [{ role: 'user', content: 'Say hello in JSON: {"message": "..."}' }]
  })
});
const data = await res.json();
console.log(data.choices[0].message.content);
```

If you see JSON back, you're good. Move on.

---

## Hour 5–10: openrouter.js

```javascript
// api/openrouter.js

const OPENROUTER_KEY = window.ENV?.OPENROUTER_KEY || '';

const SYSTEM_EN = `You are a medical triage AI. Analyze the patient's body region and symptoms.
Respond ONLY with raw valid JSON — no markdown, no backticks, no explanation.

{
  "conditions": [
    { "name": "string", "likelihood": "High|Medium|Low", "explanation": "max 20 words" }
  ],
  "severity": "Low|Medium|High|Emergency",
  "action": "One clear sentence on what the patient should do.",
  "home_tips": ["tip 1", "tip 2"],
  "warning_signs": ["sign 1"],
  "disclaimer": "This is AI information only, not medical advice. For emergencies call 115."
}

Rules:
- 2 to 3 conditions, most likely first
- "Emergency" only for life-threatening signs (chest pain radiating to arm, appendicitis, stroke)
- Keep explanations under 20 words
- Always include the disclaimer field exactly as shown`;

const SYSTEM_VI = `Bạn là AI phân loại y tế. Phân tích vùng cơ thể và triệu chứng.
Chỉ trả lời bằng JSON thuần túy — không markdown, không backtick.

{
  "conditions": [
    { "name": "string", "likelihood": "High|Medium|Low", "explanation": "tối đa 20 từ" }
  ],
  "severity": "Low|Medium|High|Emergency",
  "action": "Một câu rõ ràng về việc cần làm.",
  "home_tips": ["mẹo 1", "mẹo 2"],
  "warning_signs": ["dấu hiệu 1"],
  "disclaimer": "Đây chỉ là thông tin AI, không phải lời khuyên y tế. Cấp cứu gọi 115."
}

Trả lời bằng Tiếng Việt.`;

export async function callDiagnosis(userMessage, language = 'en') {
  const model = language === 'vi'
    ? 'qwen/qwen-2.5-72b-instruct'
    : 'anthropic/claude-3.5-sonnet';

  const system = language === 'vi' ? SYSTEM_VI : SYSTEM_EN;

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': window.location.origin,
      },
      body: JSON.stringify({
        model,
        max_tokens: 800,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: userMessage }
        ]
      })
    });

    if (!response.ok) throw new Error(`HTTP ${response.status}`);

    const data = await response.json();
    const raw = data.choices?.[0]?.message?.content || '';

    // Strip accidental markdown code fences
    const cleaned = raw.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/```$/i, '').trim();
    const parsed = JSON.parse(cleaned);

    if (!parsed.conditions || !parsed.severity) throw new Error('Bad JSON shape');

    return parsed;

  } catch (err) {
    console.error('OpenRouter error:', err);
    // Return a safe fallback so the app doesn't crash
    return {
      conditions: [{ name: 'Analysis unavailable', likelihood: 'Low',
        explanation: 'Please try again or consult a doctor directly.' }],
      severity: 'Medium',
      action: 'Please consult a doctor or visit your nearest clinic.',
      home_tips: ['Rest and monitor your symptoms'],
      warning_signs: ['Sudden worsening', 'Difficulty breathing'],
      disclaimer: 'This is AI information only, not medical advice. For emergencies call 115.'
    };
  }
}
```

---

## The Global Function (wire in index.html)

This is what Person 2's form calls when the user hits "Diagnose".
Put this in a `<script type="module">` at the bottom of `index.html`:

```javascript
import { callDiagnosis } from './api/openrouter.js';
import { speakText } from './api/elevenlabs.js';
import { renderDiagnosisCard } from './components/diagnosis-card.js';

window.runDiagnosis = async function(userMessage, language) {
  // Show loading state
  document.getElementById('loading').style.display = 'flex';
  document.getElementById('diagnosis-card').style.display = 'none';

  // Fire Claude + fal.ai in parallel
  const [diagnosis] = await Promise.all([
    callDiagnosis(userMessage, language),
    window.generateBodyImage?.(window.state?.selectedLabel),  // Person 4
  ]);

  // Hide loading, show card
  document.getElementById('loading').style.display = 'none';
  renderDiagnosisCard(diagnosis);

  // Read aloud
  const summary = `${diagnosis.conditions[0]?.name}. ${diagnosis.action}`;
  speakText(summary, language);

  // Load references after (Person 4, non-blocking)
  const topCondition = diagnosis.conditions[0]?.name;
  window.loadMedicalSources?.(topCondition, language);
};
```

---

## Hour 10–12: elevenlabs.js

```javascript
// api/elevenlabs.js

const ELEVENLABS_KEY = window.ENV?.ELEVENLABS_KEY || '';
const VOICE_ID = 'EXAVITQu4vr4xnSDxMaL'; // Sarah — works in Vietnamese too

export async function speakText(text, language = 'en') {
  if (!text || !ELEVENLABS_KEY) return;

  const btn = document.getElementById('tts-btn');
  if (btn) { btn.textContent = '🔊 Playing...'; btn.disabled = true; }

  try {
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': ELEVENLABS_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          model_id: 'eleven_multilingual_v2',
          voice_settings: { stability: 0.5, similarity_boost: 0.8 }
        })
      }
    );

    if (!response.ok) throw new Error(`ElevenLabs ${response.status}`);

    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const audio = new Audio(url);
    audio.onended = () => {
      URL.revokeObjectURL(url);
      if (btn) { btn.textContent = '🔊 Read aloud'; btn.disabled = false; }
    };
    await audio.play();

  } catch (err) {
    console.error('TTS error:', err);
    if (btn) { btn.textContent = '🔊 Read aloud'; btn.disabled = false; }
  }
}
```

---

## Prompt Test Cases

Test these in the OpenRouter playground (openrouter.ai/playground) before
integrating. Pick Claude 3.5 Sonnet, paste the system prompt, then send:

| User message | Expected severity |
|---|---|
| `Lower right abdomen, sharp, 6 hours, severity 8, fever and nausea` | High or Emergency |
| `Head, dull, 3 days, severity 4, no other symptoms` | Low |
| `Chest, pressure, 30 min, severity 9, left arm pain` | Emergency |
| `Throat, sore, 2 days, severity 3` | Low |

If any of these come back wrong, fix the system prompt before wiring the UI.

---

## Your Deliverables

- [ ] `config.js` created locally with all 4 keys
- [ ] Keys shared with team
- [ ] `api/openrouter.js` — working, tested with all 4 test cases
- [ ] `api/elevenlabs.js` — plays audio after diagnosis
- [ ] `window.runDiagnosis()` exported and working
- [ ] Emergency case returns severity "Emergency"

---

## When Something Breaks

| Problem | Fix |
|---|---|
| 401 from OpenRouter | Key wrong or not loaded — check `window.ENV` in console |
| JSON parse error | `console.log(raw)` before parse — model probably added backticks |
| TTS no sound | Browser blocks autoplay — need a user gesture first, wire to a button click |
| Model replies in English when VI | Add "You MUST reply entirely in Vietnamese" to system prompt |
| Rate limit | Switch model to `openai/gpt-4o-mini` (much cheaper fallback) |
