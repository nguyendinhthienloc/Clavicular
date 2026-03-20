from __future__ import annotations

from typing import Any, Dict, Optional

import requests


def generate_body_image(fal_key: str, prompt: str, model: str = "fal-ai/flux/schnell") -> Optional[str]:
    if not fal_key or not prompt.strip():
        return None

    response = requests.post(
        f"https://fal.run/{model}",
        headers={
            "Authorization": f"Key {fal_key}",
            "Content-Type": "application/json",
        },
        json={
            "prompt": prompt,
            "image_size": "square",
        },
        timeout=120,
    )
    response.raise_for_status()

    data: Dict[str, Any] = response.json()
    images = data.get("images", [])
    if not images:
        return None

    first = images[0]
    return first.get("url")
