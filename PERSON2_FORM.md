# Person 2 — Form + State + Voice Input
## Role: Symptom Form · App State · ElevenLabs STT · Vietnamese Mode

You are the glue. You connect the body map (Person 1) to the AI engine (Person 3).
You own all user input and all state.

---

## Your Hours

| Hours | Task |
|---|---|
| 0–1 | Kickoff — clone repo, read index.html from P1 |
| 3–7 | Build symptom form HTML + CSS |
| 7–9 | Wire app state (JS object) |
| 9–11 | Connect form submission to API trigger |
| 17–19 | ElevenLabs STT — voice input |
| 19–21 | Vietnamese language toggle |
| 24–26 | End-to-end testing |

---

## Step 1: App State Object (Hours 7–9)

Create `state/app-state.js` — this is the single source of truth for the whole app.

```javascript
// state/app-state.js

const state = {
  // Set by Person 1 body map
  selectedRegion: null,       // e.g. 'lower-right'
  selectedLabel: null,        // e.g. 'Lower right abdomen'
  regionHints: [],            // e.g. ['sharp pain', 'fever', 'nausea']

  // Set by symptom form (you)
  painType: null,             // 'sharp' | 'dull' | 'burning' | 'throbbing' | 'pressure'
  duration: null,             // e.g. '2 hours' | '3 days' | 'a week'
  severity: 5,                // 1–10
  otherSymptoms: '',          // free text
  language: 'en',            // 'en' | 'vi'

  // Set by AI (Person 3 writes, you read)
  diagnosis: null,            // full JSON from OpenRouter
  isLoading: false,

  // Setters
  setRegion(id, label, hints) {
    this.selectedRegion = id;
    this.selectedLabel = label;
    this.regionHints = hints;
    this.diagnosis = null;     // clear previous result on new region
    this.render();
  },

  setLoading(val) {
    this.isLoading = val;
    document.getElementById('loading').style.display = val ? 'flex' : 'none';
    document.getElementById('diagnose-btn').disabled = val;
    document.getElementById('diagnose-btn').textContent = val ? 'Analysing...' : 'Diagnose';
  },

  setLanguage(lang) {
    this.language = lang;
    this.applyLanguage(lang);
  },

  setDiagnosis(data) {
    this.diagnosis = data;
    this.setLoading(false);
    // Person 3's renderDiagnosisCard will be called from openrouter.js
    // after it calls this
  },

  // Re-render symptom panel visibility
  render() {
    const panel = document.getElementById('symptom-panel');
    if (this.selectedRegion) {
      panel.style.display = 'block';
      document.getElementById('selected-region-label').textContent = this.selectedLabel;
    } else {
      panel.style.display = 'none';
    }
    document.getElementById('diagnosis-card').style.display = 'none';
  },

  applyLanguage(lang) {
    const strings = LANG_STRINGS[lang] || LANG_STRINGS['en'];
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.dataset.i18n;
      if (strings[key]) el.textContent = strings[key];
    });
  },

  // Build the user message for OpenRouter
  buildPrompt() {
    return `Body region: ${this.selectedLabel}
Pain type: ${this.painType || 'not specified'}
Duration: ${this.duration || 'not specified'}
Severity (1-10): ${this.severity}
Additional symptoms: ${this.otherSymptoms || 'none'}
Language for response: ${this.language === 'vi' ? 'Vietnamese (Tiếng Việt)' : 'English'}`;
  }
};

// Internationalisation strings
const LANG_STRINGS = {
  en: {
    'form-title': 'Describe your symptoms',
    'pain-type-label': 'Type of pain',
    'duration-label': 'How long has this been happening?',
    'severity-label': 'Severity (1 = mild, 10 = unbearable)',
    'other-label': 'Any other symptoms?',
    'diagnose-btn': 'Diagnose',
    'disclaimer': 'This is not medical advice. Always consult a qualified doctor.',
    'footer-disclaimer': 'BodyCheck is an AI tool for general information only. If you are experiencing a medical emergency, call 115 immediately.',
  },
  vi: {
    'form-title': 'Mô tả triệu chứng của bạn',
    'pain-type-label': 'Loại đau',
    'duration-label': 'Triệu chứng đã bao lâu?',
    'severity-label': 'Mức độ đau (1 = nhẹ, 10 = không chịu được)',
    'other-label': 'Bạn có triệu chứng nào khác không?',
    'diagnose-btn': 'Chẩn đoán',
    'disclaimer': 'Đây không phải lời khuyên y tế. Hãy tham khảo bác sĩ.',
    'footer-disclaimer': 'BodyCheck là công cụ AI chỉ mang tính thông tin. Nếu cấp cứu, gọi 115 ngay.',
  }
};

export { state, LANG_STRINGS };
```

---

## Step 2: Symptom Form (Hours 3–7)

In `components/symptom-form.js`:

```javascript
// components/symptom-form.js
import { state } from '../state/app-state.js';

export function renderSymptomForm(containerId) {
  const container = document.getElementById(containerId);

  container.innerHTML = `
    <div style="padding: 20px;">
      <div style="font-size:18px;font-weight:600;color:#e2e8f0;margin-bottom:4px;">
        <span id="selected-region-label">Select a body region</span>
      </div>
      <div style="font-size:13px;color:#64748b;margin-bottom:20px;" data-i18n="form-title">
        Describe your symptoms
      </div>

      <!-- Pain type -->
      <div class="form-group" style="margin-bottom:16px;">
        <label style="font-size:12px;color:#94a3b8;font-weight:600;
                      letter-spacing:.05em;display:block;margin-bottom:8px;"
               data-i18n="pain-type-label">TYPE OF PAIN</label>
        <div style="display:flex;flex-wrap:wrap;gap:8px;" id="pain-type-options">
          ${['Sharp', 'Dull', 'Burning', 'Throbbing', 'Pressure'].map(type => `
            <button class="pain-option" data-value="${type.toLowerCase()}"
              onclick="selectPainType('${type.toLowerCase()}')"
              style="
                padding:7px 14px;
                border-radius:20px;
                border:1px solid #2a2d3e;
                background:#1a1d27;
                color:#94a3b8;
                font-size:13px;
                cursor:pointer;
                transition:all 0.15s;
              ">${type}</button>
          `).join('')}
        </div>
      </div>

      <!-- Duration -->
      <div class="form-group" style="margin-bottom:16px;">
        <label style="font-size:12px;color:#94a3b8;font-weight:600;
                      letter-spacing:.05em;display:block;margin-bottom:8px;"
               data-i18n="duration-label">DURATION</label>
        <select id="duration-select" onchange="state.duration = this.value"
          style="
            width:100%;
            padding:10px 12px;
            border-radius:8px;
            border:1px solid #2a2d3e;
            background:#0f1117;
            color:#e2e8f0;
            font-size:13px;
          ">
          <option value="">Select duration...</option>
          <option value="less than 1 hour">Less than 1 hour</option>
          <option value="1-6 hours">1–6 hours</option>
          <option value="since yesterday">Since yesterday</option>
          <option value="2-3 days">2–3 days</option>
          <option value="about a week">About a week</option>
          <option value="more than a week">More than a week</option>
          <option value="chronic (ongoing)">Chronic / ongoing</option>
        </select>
      </div>

      <!-- Severity slider -->
      <div class="form-group" style="margin-bottom:16px;">
        <label style="font-size:12px;color:#94a3b8;font-weight:600;
                      letter-spacing:.05em;display:block;margin-bottom:8px;"
               data-i18n="severity-label">SEVERITY</label>
        <div style="display:flex;align-items:center;gap:12px;">
          <input type="range" id="severity-slider" min="1" max="10" value="5"
            oninput="updateSeverity(this.value)"
            style="flex:1;accent-color:#6366f1;">
          <span id="severity-display" style="
            font-size:20px;font-weight:700;
            color:#6366f1;
            min-width:32px;text-align:center;
          ">5</span>
        </div>
        <div style="display:flex;justify-content:space-between;
                    font-size:11px;color:#4a5568;margin-top:4px;">
          <span>Mild</span><span>Moderate</span><span>Severe</span>
        </div>
      </div>

      <!-- Other symptoms (text + voice) -->
      <div class="form-group" style="margin-bottom:20px;">
        <label style="font-size:12px;color:#94a3b8;font-weight:600;
                      letter-spacing:.05em;display:block;margin-bottom:8px;"
               data-i18n="other-label">OTHER SYMPTOMS</label>
        <div style="position:relative;">
          <textarea id="other-symptoms" rows="3"
            oninput="state.otherSymptoms = this.value"
            placeholder="e.g. fever, nausea, dizziness..."
            style="
              width:100%;
              padding:10px 44px 10px 12px;
              border-radius:8px;
              border:1px solid #2a2d3e;
              background:#0f1117;
              color:#e2e8f0;
              font-size:13px;
              resize:vertical;
              box-sizing:border-box;
              font-family:inherit;
            "></textarea>
          <!-- Voice button — wired by Person 2 in voice-input.js -->
          <button id="mic-btn" title="Speak your symptoms"
            style="
              position:absolute;right:8px;top:8px;
              background:#1e2130;border:1px solid #2a2d3e;
              border-radius:6px;padding:6px 8px;cursor:pointer;font-size:16px;
            ">🎙</button>
        </div>
        <div id="stt-status" style="font-size:11px;color:#6366f1;margin-top:4px;display:none;">
          Listening...
        </div>
      </div>

      <!-- Submit -->
      <button id="diagnose-btn" onclick="submitDiagnosis()"
        data-i18n="diagnose-btn"
        style="
          width:100%;
          padding:14px;
          border-radius:10px;
          border:none;
          background:linear-gradient(135deg,#6366f1,#4f46e5);
          color:#fff;
          font-size:15px;
          font-weight:600;
          cursor:pointer;
          transition:opacity 0.15s;
        ">Diagnose</button>
    </div>
  `;
}

// Global helpers (called from inline onclick)
window.selectPainType = function(type) {
  state.painType = type;
  document.querySelectorAll('.pain-option').forEach(btn => {
    const isSelected = btn.dataset.value === type;
    btn.style.background = isSelected ? '#312e81' : '#1a1d27';
    btn.style.borderColor = isSelected ? '#6366f1' : '#2a2d3e';
    btn.style.color = isSelected ? '#a5b4fc' : '#94a3b8';
  });
};

window.updateSeverity = function(val) {
  state.severity = parseInt(val);
  document.getElementById('severity-display').textContent = val;
  const color = val >= 8 ? '#ef4444' : val >= 5 ? '#f59e0b' : '#22c55e';
  document.getElementById('severity-display').style.color = color;
};

// submitDiagnosis is wired in index.html to call Person 3's openrouter.js
window.submitDiagnosis = async function() {
  if (!state.selectedRegion) {
    alert('Please select a body region first');
    return;
  }
  if (!state.painType) {
    alert('Please select a pain type');
    return;
  }
  state.setLoading(true);
  // Person 3's function — imported in index.html
  await window.runDiagnosis(state.buildPrompt(), state.language);
};
```

---

## Step 3: ElevenLabs Voice Input STT (Hours 17–19)

**Get your API key**: Go to **elevenlabs.io** → Sign up (free) → Click your profile picture → "API Keys" → Create key → Copy it to `.env` as `ELEVENLABS_KEY`.

Free tier gives 10,000 characters/month TTS + STT access.

```javascript
// components/voice-input.js

const ELEVENLABS_KEY = window.ENV?.ELEVENLABS_KEY || '';

let mediaRecorder = null;
let audioChunks = [];
let isRecording = false;

export function initVoiceInput() {
  const micBtn = document.getElementById('mic-btn');
  if (!micBtn) return;

  micBtn.addEventListener('click', toggleRecording);
}

async function toggleRecording() {
  if (isRecording) {
    stopRecording();
  } else {
    await startRecording();
  }
}

async function startRecording() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder = new MediaRecorder(stream);
    audioChunks = [];

    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) audioChunks.push(e.data);
    };

    mediaRecorder.onstop = async () => {
      const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
      await transcribeAudio(audioBlob);
      stream.getTracks().forEach(t => t.stop());
    };

    mediaRecorder.start();
    isRecording = true;
    document.getElementById('mic-btn').textContent = '⏹';
    document.getElementById('mic-btn').style.borderColor = '#ef4444';
    document.getElementById('stt-status').style.display = 'block';

  } catch (err) {
    console.error('Mic access denied:', err);
    alert('Microphone access denied. Please allow mic access to use voice input.');
  }
}

function stopRecording() {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop();
  }
  isRecording = false;
  document.getElementById('mic-btn').textContent = '🎙';
  document.getElementById('mic-btn').style.borderColor = '#2a2d3e';
  document.getElementById('stt-status').textContent = 'Processing...';
}

async function transcribeAudio(audioBlob) {
  try {
    const formData = new FormData();
    formData.append('file', audioBlob, 'recording.webm');
    formData.append('model_id', 'scribe_v1');

    const response = await fetch('https://api.elevenlabs.io/v1/speech-to-text', {
      method: 'POST',
      headers: {
        'xi-api-key': ELEVENLABS_KEY,
      },
      body: formData
    });

    const data = await response.json();
    const text = data.text || '';

    if (text) {
      const textarea = document.getElementById('other-symptoms');
      textarea.value = text;
      window.state.otherSymptoms = text; // update state
      document.getElementById('stt-status').textContent = '✓ Transcribed';
    } else {
      document.getElementById('stt-status').textContent = 'Could not transcribe. Try again.';
    }

    setTimeout(() => {
      document.getElementById('stt-status').style.display = 'none';
    }, 2000);

  } catch (err) {
    console.error('STT error:', err);
    document.getElementById('stt-status').textContent = 'Voice input failed. Type manually.';
  }
}
```

In `index.html`, after form renders:
```html
<script type="module">
  import { initVoiceInput } from './components/voice-input.js';
  initVoiceInput();
</script>
```

---

## Step 4: Vietnamese Language Toggle (Hours 19–21)

In `index.html`, add the toggle button to the header:

```html
<button id="lang-toggle" onclick="toggleLanguage()"
  style="
    padding:6px 12px;
    border-radius:6px;
    border:1px solid #2a2d3e;
    background:#1a1d27;
    color:#94a3b8;
    font-size:13px;
    cursor:pointer;
  ">🇻🇳 Tiếng Việt</button>
```

In `state/app-state.js` (already written above), `applyLanguage()` updates all `data-i18n` elements.

Wire the toggle in `index.html`:

```javascript
window.toggleLanguage = function() {
  const newLang = state.language === 'en' ? 'vi' : 'en';
  state.setLanguage(newLang);
  // Also tell Person 3 to switch model
  window.currentLanguage = newLang;
  document.getElementById('lang-toggle').textContent =
    newLang === 'vi' ? '🇬🇧 English' : '🇻🇳 Tiếng Việt';
};
```

When language is `vi`, Person 3's `openrouter.js` will swap the model to `qwen/qwen-2.5-72b-instruct` (better Vietnamese) and the system prompt will instruct it to reply in Vietnamese.

---

## Step 5: Listen for Region Selection (Hours 7–9)

Person 1's body-map fires a `regionSelected` custom event. You catch it:

```javascript
// In index.html or state wiring
window.addEventListener('regionSelected', (e) => {
  const { regionId, label, hints } = e.detail;
  state.setRegion(regionId, label, hints);
  // Optionally show hints in the "Other symptoms" placeholder
  const textarea = document.getElementById('other-symptoms');
  textarea.placeholder = `e.g. ${hints.join(', ')}...`;
});
```

---

## Your Deliverables Checklist

- [ ] `state/app-state.js` — full state object with setters, buildPrompt(), language support
- [ ] `components/symptom-form.js` — pain type buttons, duration dropdown, severity slider, other textarea
- [ ] `components/voice-input.js` — mic recording, ElevenLabs STT API call, auto-fill textarea
- [ ] Language toggle wired in `index.html`
- [ ] `regionSelected` event listener connected to state
- [ ] Form submission calls `window.runDiagnosis()` (Person 3 provides this)

---

## When You're Stuck

- ElevenLabs returns 401 → API key is wrong or not set
- MediaRecorder not working → only works on HTTPS (Replit gives HTTPS by default) or localhost
- Language strings not updating → check `data-i18n` attribute is on the right elements
- Form values not in state → add `console.log(state)` before `buildPrompt()` to debug
