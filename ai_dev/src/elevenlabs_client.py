from __future__ import annotations

from pathlib import Path
from typing import Optional

import requests

VOICE_ID = "EXAVITQu4vr4xnSDxMaL"


def synthesize_speech(elevenlabs_key: str, text: str, output_file: str, language: str = "en") -> Optional[Path]:
    """Generate speech audio from text and save it as an mp3 file."""
    if not elevenlabs_key or not text.strip():
        return None

    response = requests.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}",
        headers={
            "xi-api-key": elevenlabs_key,
            "Content-Type": "application/json",
        },
        json={
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.8,
            },
        },
        timeout=45,
    )
    response.raise_for_status()

    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(response.content)
    return output_path
