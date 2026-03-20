# Claude Review Prompt (Person 3 AI Server)

Use this prompt when asking Claude for architecture and quality feedback.

## Prompt to Claude

I am Person 3 for a hackathon medical triage app. I now run a standalone Python AI server for diagnosis and TTS that other teammates consume over HTTP.

Please review these files and provide:
1. Critical bugs or reliability risks (ordered by severity).
2. Security concerns (API key handling, CORS, abuse, prompt-injection, PII safety).
3. API contract improvements for frontend/Java consumers.
4. Prompt quality improvements for medical triage JSON consistency.
5. Error-handling and timeout recommendations.
6. Minimal test plan I can run quickly during hackathon.
7. Concrete code changes (patch-style suggestions) for top 5 improvements.

Constraints:
- Keep current endpoint names unless change is absolutely necessary.
- Prioritize low-complexity fixes first.
- We are in hackathon mode, so focus on biggest impact per hour.

## Files Claude should review first

1. `ai_dev/src/server.py`
2. `ai_dev/src/openrouter_client.py`
3. `ai_dev/src/elevenlabs_client.py`
4. `ai_dev/src/config.py`
5. `ai_dev/src/main.py`
6. `ai_dev/README.md`
7. `documentation/person3/SERVER_API.md`
8. `documentation/person3/PROGRESS_DETAILED.md`

## Optional context files

1. `documentation/team/PLAN.md`
2. `documentation/team/TRACKS.md`
3. `documentation/team/API_KEYS.md`

## What not to review now

- Legacy browser AI files in `archive/legacy_js/` unless needed for migration notes.
