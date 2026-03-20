# 11:36 Progress — fal + Exa Validation

Date: 2026-03-20
Owner: Person 3

## What was tested

1. Exa live search API (URL retrieval)
2. fal live image generation API (image URL output)

## Live test results

### Exa
- Status: PASS
- Request: one minimal search query (`appendicitis symptoms site:who.int`)
- Result count: 1
- First result URL returned successfully
- Example returned URL:
  - `https://applications.emro.who.int/imemrf/Pak_J_Med_Sci/Pak_J_Med_Sci_2009_25_3_490.pdf`

### fal
- Status: FAIL (403 Forbidden)
- Request: one minimal image generation call to `fal-ai/flux/schnell`
- Result: request blocked with 403
- Interpretation: key is present but currently not authorized for this endpoint/model (or key is invalid/expired)

## Cost impact notes

- Exa: one live query was used.
- fal: image was not generated due to 403, so no successful generation charge occurred.

## Current conclusion

- Exa integration is operational.
- fal integration is not operational yet and needs key/permission fix before Person 4 image features can go live.

## Immediate fix steps for fal

1. Regenerate FAL key from dashboard and update `.env` (`FAL_KEY=...`).
2. Re-run one single test call to `https://fal.run/fal-ai/flux/schnell`.
3. If still 403, verify account/model access on fal dashboard and switch to a model your key can access.
4. Once fixed, add one backend endpoint for image generation in Person 4 integration path.

## Suggested handoff message to Person 4

- "Exa is working with live URL output. fal currently returns 403 Forbidden with current key. Please rotate key/check model permissions, then I can retest immediately."
