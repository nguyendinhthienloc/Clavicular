# BodyCheck — LotusHacks 2026 Master Plan

> **Event**: LotusHacks × HackHarvard × GenAI Fund  
> **Date**: March 20–22, 2026 | VNG Campus, Ho Chi Minh City  
> **Duration**: 30 hours (MVP scope)  
> **Team**: 4 people

---

## What We're Building

**BodyCheck** is an AI-powered medical triage web app. Users tap a part of their body that hurts, answer 3–5 follow-up questions, and receive an instant AI-generated diagnosis with severity rating, recommended actions, and real medical references — all readable aloud in Vietnamese or English.

---

## LotusHacks Track Alignment

| Track | Sponsor | How BodyCheck Qualifies |
|---|---|---|
| **Social & Mobility** | TASCO | Healthcare accessibility for underserved Vietnamese communities |
| **Technology & Consumer** | AWS | Mobile-first consumer health app with AI |
| **Enterprise** | TinyFish | B2B triage tool for clinics and insurance companies |
| **EdTech** | ETEST | Medical education: learn anatomy by exploring symptoms |

**Primary track**: Social & Mobility. **Pitch all four** in the deck.

---

## Team Files (read yours)

| Person | Role | File |
|---|---|---|
| Person 1 | UI Lead — HTML/CSS + Body Map | [PERSON1_UI.md](./PERSON1_UI.md) |
| Person 2 | Form + State + Voice Input | [PERSON2_FORM.md](./PERSON2_FORM.md) |
| Person 3 | AI Core — LLM + TTS | [PERSON3_AI.md](./PERSON3_AI.md) |
| Person 4 | AI Extras + Deploy + Pitch | [PERSON4_DEPLOY.md](./PERSON4_DEPLOY.md) |

---

## Tech Stack (Final)

### Frontend
- **HTML5 + CSS3** — no framework, plain files
- **Vanilla JavaScript** — no build step needed for MVP
- **Lovable.dev** — AI-generate the base HTML shell in minutes (free, sponsor)
- **react-body-highlighter** — pre-mapped SVG body map with clickable regions

### AI Services (all free)
| Service | Use | Get Key At |
|---|---|---|
| **OpenRouter** | Claude + Qwen LLM calls | openrouter.ai → Sign up → Keys |
| **fal.ai** | Body region image generation | fal.ai → Dashboard → API Keys |
| **ElevenLabs** | Voice input (STT) + readback (TTS) | elevenlabs.io → Profile → API Key |
| **Exa.ai** | Medical reference search | exa.ai → Dashboard → API Key |

### Infrastructure
- **Replit** — deploy, get shareable URL instantly (sponsor)
- **GitHub** — version control, one repo, four branches

---

## Repository Structure

```
bodycheck/
├── index.html              ← Person 1 owns
├── styles/
│   ├── main.css            ← Person 1 owns
│   └── diagnosis.css       ← Person 1 owns
├── components/
│   ├── body-map.js         ← Person 1 owns
│   ├── symptom-form.js     ← Person 2 owns
│   ├── voice-input.js      ← Person 2 owns
│   └── diagnosis-card.js   ← Person 1 owns (UI), Person 3 wires data
├── api/
│   ├── openrouter.js       ← Person 3 owns
│   ├── elevenlabs.js       ← Person 3 owns
│   ├── fal.js              ← Person 4 owns
│   └── exa.js              ← Person 4 owns
├── state/
│   └── app-state.js        ← Person 2 owns
├── data/
│   └── body-regions.js     ← Person 1 owns
├── .env.example            ← Person 3 creates
└── README.md               ← Person 4 writes
```

---

## 30-Hour Timeline (All Four)

```
Hour  0–1   [ALL]     Kickoff — roles, repo, API keys, .env setup
Hour  1–3   [P1]      Lovable.dev scaffold → HTML shell
Hour  1–3   [P3]      OpenRouter account + first test call
Hour  3–7   [P1]      Body map SVG integration
Hour  3–7   [P2]      Symptom form HTML + CSS
Hour  7–9   [P2]      App state wiring (JS object)
Hour  7–11  [P3]      LLM prompt + JSON parse + error handling
Hour  9–11  [P1]      Diagnosis card UI
Hour  11–13 [P3]      ElevenLabs TTS integration
Hour  11–14 [P4]      fal.ai image generation
Hour  14–17 [P4]      Exa.ai medical references
Hour  17–19 [P2]      ElevenLabs STT voice input
Hour  19–21 [P2]      Vietnamese language mode (Qwen swap)
Hour  21–24 [P1]      Mobile CSS polish
Hour  24–26 [ALL]     Integration testing + bug fixes
Hour  26–27 [P4]      Replit deploy + public URL
Hour  27–29 [P4]      Demo video recording + pitch deck
Hour  29–30 [ALL]     Rehearse demo, final check
```

---

## API Keys Needed (Hour 0)

Person 3 collects all keys and shares via team chat BEFORE anyone writes API code.

```
OPENROUTER_KEY=sk-or-...        # openrouter.ai
FAL_KEY=...                     # fal.ai
ELEVENLABS_KEY=...              # elevenlabs.io
EXA_KEY=...                     # exa.ai
```

Store in `.env` file. Never commit to GitHub (add to `.gitignore`).

---

## Medical Disclaimer (Required Everywhere)

> *"BodyCheck is an AI tool for general information only and is not a substitute for professional medical advice, diagnosis, or treatment. If you are experiencing a medical emergency, call 115 immediately."*

This text MUST appear: in every AI system prompt, on the diagnosis card, and in the app footer.

---

## How to Win

1. **Demo works live** — judges watch the full flow: tap → speak → diagnose → hear result
2. **6+ AI tools visible** — call out fal, ElevenLabs, Exa, OpenRouter in the pitch
3. **Vietnamese language** — shows local impact, huge in Vietnam context
4. **Hit all 4 tracks** — spend 30 seconds per track in the pitch
5. **Sponsor tools** = sponsor prizes — double the prize pool eligibility
