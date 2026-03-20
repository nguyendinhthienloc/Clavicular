# Next Steps — Migrate fal to Gemini

---

## Step 1: Add Gemini key to .env
```
GEMINI_KEY=your_gemini_key_here
```
Restart server after.

---

## Step 2: Create gemini_client.py

Create `ai_dev/src/gemini_client.py`:

```python
from __future__ import annotations
import requests


def generate_body_image(region_name: str, gemini_key: str) -> str | None:
    if not gemini_key or not region_name:
        return None

    try:
        response = requests.post(
            f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key={gemini_key}",
            json={
                "contents": [{
                    "parts": [{
                        "text": f"Medical illustration of the human {region_name}, highlighted in red, clean white background, anatomical diagram style, no text labels"
                    }]
                }],
                "generationConfig": {
                    "responseModalities": ["IMAGE", "TEXT"]
                }
            },
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
        image_b64 = data["candidates"][0]["content"]["parts"][0]["inlineData"]["data"]
        return f"data:image/png;base64,{image_b64}"

    except Exception as e:
        print(f"Gemini image error: {e}")
        return None
```

---

## Step 3: Add image endpoint to server.py

Add this to `server.py`:

```python
# add to imports at top
from .gemini_client import generate_body_image   # or without dot if running directly

class ImageRequest(BaseModel):
    region_name: str = Field(min_length=1)

@app.post("/api/image")
def image(payload: ImageRequest):
    gemini_key = get_env("GEMINI_KEY")
    image_data = generate_body_image(payload.region_name, gemini_key)
    if not image_data:
        raise HTTPException(status_code=502, detail="Image generation failed")
    return {"success": True, "image": image_data}
```

---

## Step 4: Test it
```bash
curl -X POST http://localhost:8000/api/image \
  -H "Content-Type: application/json" \
  -d '{"region_name": "lower right abdomen"}'
```

Expected response:
```json
{
  "success": true,
  "image": "data:image/png;base64,/9j/4AAQ..."
}
```

---

## Step 5: Tell Person 1 the new endpoint

They call it like this after diagnosis renders:

```javascript
const res = await fetch('http://YOUR_IP:8000/api/image', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ region_name: selectedRegion })
});
const { image } = await res.json();
document.getElementById('body-illustration').src = image;
```

---

## What to delete
- Remove `FAL_KEY` from `.env`
- Delete or ignore `fal.js` and any fal references in the codebase

---

## If Gemini returns an error about the model name
Try this model instead:
```
gemini-2.0-flash-preview-image-generation
```
Or check available models at:
```
https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_GEMINI_KEY
```
