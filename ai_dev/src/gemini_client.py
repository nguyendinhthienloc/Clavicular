from __future__ import annotations

from typing import Any, Dict, Optional

import requests


MODEL_CANDIDATES = [
    "gemini-2.5-flash-image",
    "gemini-2.5-flash-preview-image",
    "gemini-2.0-flash",
]


def _try_generate(model_name: str, region_name: str, gemini_key: str) -> Optional[str]:
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
        f"?key={gemini_key}"
    )

    payload: Dict[str, Any] = {
        "contents": [
            {
                "parts": [
                    {
                        "text": (
                            f"Medical illustration of the human {region_name}, highlighted in red, "
                            "clean white background, anatomical diagram style, no text labels"
                        )
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
        },
    }

    response = requests.post(url, json=payload, timeout=45)
    response.raise_for_status()
    data = response.json()

    candidates = data.get("candidates", [])
    if not candidates:
        return None

    parts = candidates[0].get("content", {}).get("parts", [])
    for part in parts:
        inline = part.get("inlineData")
        if inline and inline.get("data"):
            image_b64 = inline["data"]
            mime = inline.get("mimeType", "image/png")
            return f"data:{mime};base64,{image_b64}"

    return None


def generate_body_image(region_name: str, gemini_key: str) -> Optional[str]:
    if not gemini_key or not region_name:
        return None

    for model_name in MODEL_CANDIDATES:
        try:
            result = _try_generate(model_name, region_name, gemini_key)
            if result:
                return result
        except Exception:
            continue

    return None
