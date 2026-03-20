# Person 1 — UI Lead
## Role: HTML + CSS + Body Map + Diagnosis Card

You own everything the user sees. Your job is to make the app look credible
enough that a judge trusts a medical diagnosis from it.

---

## Your Hours

| Hours | Task |
|---|---|
| 0–1 | Kickoff — clone repo, install nothing (vanilla HTML), get .env from P3 |
| 1–3 | Lovable.dev scaffold — generate base HTML shell with AI |
| 3–7 | Body map SVG integration |
| 9–11 | Diagnosis card UI |
| 21–24 | Mobile polish + final CSS |
| 24–26 | Integration testing support |

---

## Step 1: Lovable.dev Scaffold (Hours 1–3)

**What**: Use Lovable.dev to generate the base HTML layout in minutes using AI.

**How**:
1. Go to **lovable.dev** (free, LotusHacks sponsor)
2. Sign up with GitHub
3. Click "New Project" → "Chat to build"
4. Paste this prompt:

```
Build a single-page medical triage web app called BodyCheck.
Dark background (#0f1117), white text. No frameworks, pure HTML/CSS/JS.
Layout:
- Top bar: logo "BodyCheck" left, "🇻🇳 Tiếng Việt" toggle right
- Left panel (40% width): placeholder div id="body-map-container"
- Right panel (60% width): placeholder div id="symptom-panel" (hidden by default)
- Bottom: sticky footer with disclaimer text
- A loading spinner div id="loading" (hidden by default)
- A diagnosis card div id="diagnosis-card" (hidden by default)
Color palette: background #0f1117, card #1a1d27, accent #6366f1, 
danger red #ef4444, warning amber #f59e0b, safe green #22c55e
Make it mobile responsive with a single column on small screens.
```

5. Download the generated HTML/CSS
6. Put `index.html` in repo root, CSS in `styles/main.css`
7. Commit: `git add . && git commit -m "feat: base scaffold from Lovable"`

**Expected output**: A clean dark-themed shell with the right divs in place.

---

## Step 2: Body Map Integration (Hours 3–7)

### Option A: SVG file (simplest, no npm needed)

Download a free human body SVG:
- URL: `https://upload.wikimedia.org/wikipedia/commons/1/19/Human_body_silhouette.svg`
- Or search Wikimedia Commons for "human body outline"

Then in `body-map.js`:

```javascript
// components/body-map.js

const REGIONS = {
  'head':         { label: 'Head', hints: ['headache', 'dizziness', 'vision'] },
  'neck':         { label: 'Neck', hints: ['stiffness', 'sore throat', 'swelling'] },
  'chest':        { label: 'Chest', hints: ['tightness', 'shortness of breath', 'palpitations'] },
  'upper-abdomen':{ label: 'Upper abdomen', hints: ['nausea', 'bloating', 'heartburn'] },
  'lower-abdomen':{ label: 'Lower abdomen', hints: ['cramping', 'gas', 'tenderness'] },
  'lower-right':  { label: 'Lower right abdomen', hints: ['sharp pain', 'fever', 'nausea'] },
  'lower-left':   { label: 'Lower left abdomen', hints: ['cramping', 'constipation', 'pain'] },
  'back-upper':   { label: 'Upper back', hints: ['muscle ache', 'stiffness', 'spasm'] },
  'back-lower':   { label: 'Lower back', hints: ['sciatica', 'muscle strain', 'disc'] },
  'shoulder-l':   { label: 'Left shoulder', hints: ['stiffness', 'rotator cuff', 'ache'] },
  'shoulder-r':   { label: 'Right shoulder', hints: ['stiffness', 'rotator cuff', 'ache'] },
  'arm-l':        { label: 'Left arm', hints: ['numbness', 'tingling', 'weakness'] },
  'arm-r':        { label: 'Right arm', hints: ['numbness', 'tingling', 'weakness'] },
  'hand-l':       { label: 'Left hand', hints: ['tingling', 'swelling', 'stiffness'] },
  'hand-r':       { label: 'Right hand', hints: ['tingling', 'swelling', 'stiffness'] },
  'hip-l':        { label: 'Left hip', hints: ['joint pain', 'stiffness', 'clicking'] },
  'hip-r':        { label: 'Right hip', hints: ['joint pain', 'stiffness', 'clicking'] },
  'knee-l':       { label: 'Left knee', hints: ['swelling', 'locking', 'instability'] },
  'knee-r':       { label: 'Right knee', hints: ['swelling', 'locking', 'instability'] },
  'foot-l':       { label: 'Left foot', hints: ['plantar fasciitis', 'swelling', 'numbness'] },
  'foot-r':       { label: 'Right foot', hints: ['plantar fasciitis', 'swelling', 'numbness'] },
};

// Build a simple clickable SVG grid if react-body-highlighter not available
function renderBodyGrid(containerId) {
  const container = document.getElementById(containerId);
  const regions = Object.entries(REGIONS);

  const grid = document.createElement('div');
  grid.style.cssText = `
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    padding: 12px;
  `;

  regions.forEach(([id, { label }]) => {
    const btn = document.createElement('button');
    btn.dataset.region = id;
    btn.textContent = label;
    btn.style.cssText = `
      padding: 10px 6px;
      border-radius: 8px;
      border: 1px solid #2a2d3e;
      background: #1a1d27;
      color: #e2e8f0;
      font-size: 11px;
      cursor: pointer;
      transition: background 0.15s, border-color 0.15s;
      text-align: center;
      line-height: 1.3;
    `;
    btn.addEventListener('mouseenter', () => {
      btn.style.background = '#252940';
      btn.style.borderColor = '#6366f1';
    });
    btn.addEventListener('mouseleave', () => {
      if (!btn.classList.contains('selected')) {
        btn.style.background = '#1a1d27';
        btn.style.borderColor = '#2a2d3e';
      }
    });
    btn.addEventListener('click', () => {
      // Clear previous selection
      grid.querySelectorAll('button').forEach(b => {
        b.classList.remove('selected');
        b.style.background = '#1a1d27';
        b.style.borderColor = '#2a2d3e';
      });
      // Select this one
      btn.classList.add('selected');
      btn.style.background = '#312e81';
      btn.style.borderColor = '#6366f1';
      // Fire event for Person 2 to catch
      window.dispatchEvent(new CustomEvent('regionSelected', {
        detail: { regionId: id, label: label, hints: REGIONS[id].hints }
      }));
    });
    grid.appendChild(btn);
  });

  container.appendChild(grid);

  // Front/Back toggle
  const toggle = document.createElement('div');
  toggle.innerHTML = `
    <div style="display:flex;gap:8px;margin-bottom:12px;justify-content:center;">
      <button id="btn-front" onclick="switchView('front')"
        style="padding:6px 16px;border-radius:6px;background:#312e81;
               border:1px solid #6366f1;color:#a5b4fc;cursor:pointer;font-size:12px;">
        Front
      </button>
      <button id="btn-back" onclick="switchView('back')"
        style="padding:6px 16px;border-radius:6px;background:#1a1d27;
               border:1px solid #2a2d3e;color:#94a3b8;cursor:pointer;font-size:12px;">
        Back
      </button>
    </div>
  `;
  container.insertBefore(toggle, grid);
}

window.switchView = function(view) {
  document.getElementById('btn-front').style.background = view==='front' ? '#312e81' : '#1a1d27';
  document.getElementById('btn-back').style.background  = view==='back'  ? '#312e81' : '#1a1d27';
  // Could swap SVG layers here if using full SVG
  console.log('View switched to:', view);
};

export { renderBodyGrid, REGIONS };
```

In `index.html`, after body loads:
```html
<script type="module">
  import { renderBodyGrid } from './components/body-map.js';
  renderBodyGrid('body-map-container');
</script>
```

### Option B: react-body-highlighter (if using Vite)
If the team decides to use Vite for build tooling:
```bash
npm install react-body-highlighter
```
But for this hackathon, Option A (plain HTML) is faster.

---

## Step 3: Diagnosis Card UI (Hours 9–11)

In `components/diagnosis-card.js`:

```javascript
// components/diagnosis-card.js

const SEVERITY_CONFIG = {
  'Low':       { color: '#22c55e', bg: '#052e16', label: 'Low severity',  icon: '✓' },
  'Medium':    { color: '#f59e0b', bg: '#1c1408', label: 'See a pharmacist', icon: '!' },
  'High':      { color: '#ef4444', bg: '#1f0606', label: 'See a doctor',  icon: '!!' },
  'Emergency': { color: '#dc2626', bg: '#1f0606', label: 'EMERGENCY — call 115', icon: '🚨' },
};

export function renderDiagnosisCard(data) {
  // data = { conditions, severity, action, home_tips, warning_signs,
  //          imageUrl, sources, disclaimer }
  const cfg = SEVERITY_CONFIG[data.severity] || SEVERITY_CONFIG['Medium'];

  const card = document.getElementById('diagnosis-card');
  card.style.display = 'block';
  card.style.cssText += `
    background: #1a1d27;
    border: 1px solid ${cfg.color}44;
    border-radius: 12px;
    padding: 20px;
    margin-top: 16px;
  `;

  card.innerHTML = `
    <!-- Severity badge -->
    <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px;">
      <span style="
        background:${cfg.bg};
        color:${cfg.color};
        border:1px solid ${cfg.color};
        padding:4px 12px;
        border-radius:20px;
        font-size:12px;
        font-weight:600;
      ">${cfg.icon} ${data.severity}</span>
      <span style="color:#94a3b8;font-size:13px;">${cfg.label}</span>
      <button id="tts-btn" style="
        margin-left:auto;
        background:#1e2130;
        border:1px solid #2a2d3e;
        color:#94a3b8;
        padding:4px 10px;
        border-radius:6px;
        cursor:pointer;
        font-size:12px;
      ">🔊 Read aloud</button>
    </div>

    <!-- Body illustration from fal.ai -->
    <div id="body-illustration" style="margin-bottom:16px;">
      <div style="background:#0f1117;border-radius:8px;height:120px;
                  display:flex;align-items:center;justify-content:center;
                  color:#4a5568;font-size:13px;">
        Generating illustration...
      </div>
    </div>

    <!-- Conditions -->
    <div style="margin-bottom:16px;">
      <div style="font-size:13px;font-weight:600;color:#94a3b8;
                  margin-bottom:8px;text-transform:uppercase;letter-spacing:.06em;">
        Possible conditions
      </div>
      ${data.conditions.map(c => `
        <div style="
          border-left:3px solid ${likelihoodColor(c.likelihood)};
          padding:8px 12px;
          margin-bottom:8px;
          background:#0f1117;
          border-radius:0 8px 8px 0;
        ">
          <div style="font-weight:600;color:#e2e8f0;font-size:14px;">${c.name}
            <span style="font-size:11px;color:${likelihoodColor(c.likelihood)};
                         margin-left:6px;">${c.likelihood}</span>
          </div>
          <div style="color:#94a3b8;font-size:12px;margin-top:4px;">${c.explanation}</div>
        </div>
      `).join('')}
    </div>

    <!-- Action -->
    <div style="
      background:${cfg.bg};
      border:1px solid ${cfg.color}66;
      border-radius:8px;
      padding:12px;
      margin-bottom:16px;
    ">
      <div style="font-size:13px;font-weight:600;color:${cfg.color};">
        Recommended action
      </div>
      <div style="color:#e2e8f0;margin-top:4px;">${data.action}</div>
    </div>

    <!-- Home tips -->
    ${data.home_tips?.length ? `
    <div style="margin-bottom:16px;">
      <div style="font-size:13px;font-weight:600;color:#94a3b8;margin-bottom:8px;">
        What you can do now
      </div>
      ${data.home_tips.map(tip => `
        <div style="display:flex;gap:8px;padding:4px 0;color:#cbd5e1;font-size:13px;">
          <span style="color:#6366f1;">→</span> ${tip}
        </div>
      `).join('')}
    </div>` : ''}

    <!-- Warning signs -->
    ${data.warning_signs?.length ? `
    <div style="
      background:#1c0a0a;
      border:1px solid #ef444433;
      border-radius:8px;
      padding:12px;
      margin-bottom:16px;
    ">
      <div style="font-size:13px;font-weight:600;color:#ef4444;margin-bottom:6px;">
        ⚠ Seek emergency care if you have
      </div>
      ${data.warning_signs.map(w => `
        <div style="color:#fca5a5;font-size:13px;padding:2px 0;">${w}</div>
      `).join('')}
    </div>` : ''}

    <!-- Medical sources (filled by Person 4 / Exa.ai) -->
    <div id="medical-sources"></div>

    <!-- Disclaimer -->
    <div style="
      font-size:11px;
      color:#4a5568;
      border-top:1px solid #1e2130;
      padding-top:12px;
      margin-top:4px;
      line-height:1.5;
    ">${data.disclaimer}</div>
  `;
}

function likelihoodColor(l) {
  return l === 'High' ? '#ef4444' : l === 'Medium' ? '#f59e0b' : '#22c55e';
}
```

---

## Step 4: CSS Polish — Mobile (Hours 21–24)

In `styles/main.css`, add at the bottom:

```css
/* Mobile responsive */
@media (max-width: 768px) {
  .app-layout {
    flex-direction: column;
  }
  .left-panel, .right-panel {
    width: 100% !important;
  }
  .body-grid {
    grid-template-columns: repeat(2, 1fr) !important;
  }
}

/* Loading state */
.skeleton {
  background: linear-gradient(90deg, #1a1d27 25%, #252940 50%, #1a1d27 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 6px;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* Severity badge animations */
.badge-emergency {
  animation: pulse 1s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.75; }
}
```

---

## Your Deliverables Checklist

- [ ] `index.html` — full page structure with all divs in place
- [ ] `styles/main.css` — dark theme, layout, mobile responsive
- [ ] `components/body-map.js` — clickable regions, front/back toggle
- [ ] `components/diagnosis-card.js` — severity badge, conditions, tips, disclaimer
- [ ] `data/body-regions.js` — region metadata (copy REGIONS from above)
- [ ] App looks good on iPhone screen size (375px wide)

---

## When You're Stuck

- Body map not clickable → check that `dispatchEvent` is firing, add `console.log` inside click handler
- CSS not loading → check `<link rel="stylesheet">` path in `index.html`
- Card not appearing → check `display: none` vs `display: block` toggle
