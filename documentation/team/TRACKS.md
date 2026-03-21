# LotusHacks 2026 — Track Alignment Guide
## How BodyCheck satisfies all four tracks

Use this document when writing the pitch and talking to judges.

---

## Track 1: Social & Mobility by TASCO
### Theme: Technology for social good and community impact

**Primary track — lead with this.**

### The Problem (use these numbers)
- Vietnam has ~9 doctors per 10,000 people (WHO recommends 23)
- Rural areas have even lower coverage — many provinces have fewer than 3
- Patients often wait days or weeks for an appointment for basic triage
- Many Vietnamese self-diagnose using social media, leading to misinformation

### How BodyCheck Solves It
- Instant AI triage accessible from any smartphone, no app download
- Works in Vietnamese — critical for non-English speakers
- Helps users understand severity: is this a "rest at home" or "go to hospital" situation?
- Reduces unnecessary ER visits AND ensures serious conditions get escalated immediately
- Free to use — no subscription, no paywall

### Pitch Language
> "Vietnam's healthcare system is under strain. BodyCheck democratises access to basic medical triage — giving every Vietnamese citizen, regardless of location or income, the ability to make informed decisions about their health. Our AI speaks Vietnamese, understands local conditions, and tells users exactly when to call 115."

---

## Track 2: Technology & Consumer by AWS

### Theme: Applications designed for everyday users

### How BodyCheck Qualifies
- Mobile-first design — works on any browser, any phone
- Progressive Web App (PWA) — can be added to home screen
- No technical knowledge required — tap, speak, read
- Voice interface removes literacy barriers
- Multilingual (EN + VI) from day one

### Technical Highlights for AWS Track
- Serverless architecture — runs entirely on free hosting (Replit/Netlify)
- Uses AWS-adjacent cloud services (could be migrated to AWS Lambda)
- ElevenLabs real-time voice streaming
- fal.ai inference on the edge

### Pitch Language
> "BodyCheck is a zero-friction consumer health app. No registration. No download. No waiting room. Just tap where it hurts and get an answer in seconds — in English or Vietnamese. We designed for the 70 million smartphone users in Vietnam who deserve instant access to healthcare guidance."

---

## Track 3: Enterprise by TinyFish
### Theme: Solutions for large-scale business challenges

### B2B Use Case
BodyCheck isn't just for individual consumers. It can be white-labelled and deployed by:

| Customer | Use Case | Value |
|---|---|---|
| **Clinics & hospitals** | Patient pre-screening kiosk — reduces triage nurse workload | Save 5–10 min per patient |
| **Insurance companies** | First-pass claims assessment — did the injury match the complaint? | Reduce fraud |
| **Corporate HR** | Employee health triage — reduces unnecessary sick days + doctor visits | Cost savings |
| **Pharmacies** | Upsell the right OTC medication based on AI diagnosis | Increase revenue |
| **Telemedicine platforms** | Collect structured symptom data before connecting to a doctor | Better consultations |

### Enterprise Features to Mention
- API-first architecture — easy to integrate into existing systems
- JSON diagnosis output — structured data for downstream processing
- Multi-language support — scales across SE Asia
- Audit log ready — every diagnosis can be logged for compliance

### Pitch Language
> "For enterprise customers, BodyCheck is a white-label AI triage API. Clinics can embed it in their patient intake flow, insurance companies can use it for claims pre-assessment, and pharmacies can use it to recommend the right OTC products. We're not just a consumer app — we're a healthcare AI platform."

---

## Track 4: EdTech by ETEST
### Theme: Innovations in education and learning

### How BodyCheck Teaches
- Users learn anatomy by interacting with a body map — clicking regions reinforces body part names
- The diagnosis card explains WHY a condition is likely — educational, not just prescriptive
- fal.ai generates anatomical illustrations that show the affected area — visual learning
- Medical sources from Exa.ai link to trusted educational content
- Over time, users learn to recognise warning signs and red flags

### For Students and Medical Education
- Could be used in nursing/medical schools as a clinical reasoning exercise
- "What diagnosis would you give this symptom set?" — guided learning mode
- Vietnamese medical vocabulary in the VI mode teaches medical terms in both languages

### Potential EdTech Extension (mention as stretch goal)
- "Learning mode" — instead of giving the answer, ask the user to guess and then reveal
- Anatomy quiz mode — "where would you click for lower back pain?"
- Progress tracking — "You've correctly identified 12 conditions this week"

### Pitch Language
> "BodyCheck makes medical education interactive and accessible. By exploring symptoms on a body map and reading AI-generated explanations backed by real medical literature, users learn anatomy and clinical reasoning — not just get an answer. For ETEST's mission of smart, engaging education, BodyCheck is anatomy learning reimagined."

---

## Unified Pitch Structure (30 seconds per track)

**Opening** (30s):
> "BodyCheck is an AI medical triage app where you tap where it hurts and get an instant diagnosis. We built it in 30 hours at LotusHacks."

**Track 1 — Social** (30s):
> "For TASCO's Social track: Vietnam has a doctor shortage. BodyCheck gives every Vietnamese citizen instant triage, in Vietnamese, for free."

**Track 2 — Consumer** (30s):
> "For AWS's Consumer track: zero friction, no download, works on any phone. Voice input, image output, 6 AI integrations."

**Track 3 — Enterprise** (20s):
> "For TinyFish's Enterprise track: clinics can embed our JSON API for patient pre-screening. Insurance companies can use it for claims triage."

**Track 4 — EdTech** (20s):
> "For ETEST's EdTech track: learning anatomy by interacting with symptoms is more effective than reading a textbook. BodyCheck makes medical education tangible."

**Close** (10s):
> "Six AI tools. Four tracks. Thirty hours. BodyCheck."

---

## Sponsor Prize Opportunities

Beyond the track prizes, these sponsors have their own awards:

| Sponsor | What They Reward | Your Hook |
|---|---|---|
| **fal.ai** | Best use of fal.ai | Medical illustration generation per diagnosis |
| **ElevenLabs** | Best voice AI integration | Bilingual STT + TTS with medical context |
| **Exa.ai** | Best use of Exa search | Medical reference retrieval with domain filtering |
| **OpenRouter** | Best multi-model app | Claude (EN) + Qwen (VI) routing |
| **Lovable.dev** | Best AI-built UI | Entire frontend scaffolded with Lovable |
| **AWS** | Best consumer app | Mobile-first PWA on AWS-compatible infrastructure |

Stack as many as possible — you can win track prize AND sponsor prizes simultaneously.
