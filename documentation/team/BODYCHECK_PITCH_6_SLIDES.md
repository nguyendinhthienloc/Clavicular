---
marp: true
theme: default
paginate: true
title: BodyCheck - AI Medical Triage
---

# BodyCheck
## AI Medical Triage for Faster, Safer Decisions

LotusHacks 2026 | Team of 4 | 30-hour MVP

### Vision
Give anyone instant first-pass health guidance by combining body-map interaction, clinical AI reasoning, and voice support in English and Vietnamese.

---

# The Problem We Solve

- Healthcare access is uneven, especially for rural and busy communities.
- People often delay care or self-diagnose from unreliable social media sources.
- Early triage is slow, expensive, or unavailable outside clinic hours.

### What users need
- Fast symptom understanding
- Clear urgency guidance (home care vs. urgent care)
- Trusted references and simple language

---

# Our Solution: BodyCheck Flow

1. User taps body region with pain/discomfort.
2. User adds symptoms (text or voice).
3. AI asks follow-up questions and reasons over risk.
4. User receives:
   - likely conditions
   - severity rating
   - recommended next actions
   - medical references
5. Result can be read aloud with TTS.

### Safety principle
BodyCheck supports triage decisions, not final diagnosis.

---

# Technical Architecture (MVP)

### Frontend
- Flutter app + web UI workstream
- Body map + symptom capture + multilingual UX

### AI Backend (Python FastAPI)
- `/api/chat`: clinician-style conversational triage with session memory
- `/api/diagnose`: structured first-pass diagnosis
- `/api/clinics`: nearby clinic recommendations
- `/api/tts`: spoken guidance output

### Integrations
- Codex for coding acceleration, debugging support, and rapid iteration
- OpenRouter/OpenAI-compatible LLM routing
- ElevenLabs voice
- Exa.ai medical source retrieval

---

# Demo Value and Track Fit

### Live demo story
Tap where it hurts -> describe symptoms -> receive triage + urgency + references -> hear the answer.

### Why this can win
- **Social & Mobility**: better healthcare accessibility
- **Technology & Consumer**: mobile-first, low-friction experience
- **Enterprise**: API-ready triage layer for clinics/insurers
- **EdTech**: anatomy + symptom learning through interaction

### Bonus
Strong sponsor-tool alignment across multiple AI services.

---

# Roadmap and Ask

### Next 2 weeks
- Improve medical guardrails and emergency escalation logic
- Expand Vietnamese clinical phrasing quality
- Add analytics for triage outcomes and model confidence
- Harden deployment + monitoring

### What we ask
- Pilot opportunities with clinics/universities
- Mentorship on medical safety validation
- Partner feedback on enterprise integration use cases

## BodyCheck
Fast triage. Better decisions. Earlier care.
