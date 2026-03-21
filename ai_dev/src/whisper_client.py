from __future__ import annotations

from typing import Optional

import requests


WHISPER_URL = "https://api.openai.com/v1/audio/transcriptions"
SUPPORTED_LANGUAGES = {"en": "en", "vi": "vi"}


def transcribe_audio(
    audio_bytes: bytes,
    openai_key: str,
    language: str = "en",
    filename: str = "audio.webm",
) -> Optional[str]:
    """Send audio bytes to OpenAI Whisper and return transcribed text."""
    if not openai_key or not audio_bytes:
        return None

    lang_code = SUPPORTED_LANGUAGES.get(language, "en")

    try:
        response = requests.post(
            WHISPER_URL,
            headers={"Authorization": f"Bearer {openai_key}"},
            files={
                # Let requests infer multipart boundaries while preserving filename.
                "file": (filename, audio_bytes),
            },
            data={
                "model": "whisper-1",
                "language": lang_code,
                "response_format": "text",
            },
            timeout=30,
        )
        response.raise_for_status()
        return response.text.strip()
    except Exception as exc:
        print(f"[whisper] transcription error: {exc}")
        return None