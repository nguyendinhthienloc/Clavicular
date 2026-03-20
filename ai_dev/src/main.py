from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from .config import get_env, load_env
    from .elevenlabs_client import synthesize_speech
    from .openrouter_client import call_diagnosis
except ImportError:
    from config import get_env, load_env
    from elevenlabs_client import synthesize_speech
    from openrouter_client import call_diagnosis


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="BodyCheck AI development CLI")
    parser.add_argument("--message", type=str, required=True, help="Symptoms prompt text")
    parser.add_argument("--language", type=str, default="en", choices=["en", "vi"])
    parser.add_argument("--tts", action="store_true", help="Generate TTS audio from diagnosis summary")
    parser.add_argument("--out", type=str, default="ai_dev/output/diagnosis_tts.mp3", help="Output mp3 path")
    parser.add_argument("--dry-run", action="store_true", help="Skip external API calls and return fallback diagnosis")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    load_env()

    openrouter_key = get_env("OPENROUTER_KEY")
    elevenlabs_key = get_env("ELEVENLABS_KEY")

    if args.dry_run:
        openrouter_key = ""

    diagnosis = call_diagnosis(openrouter_key, args.message, args.language)
    print(json.dumps(diagnosis, ensure_ascii=False, indent=2))

    if args.tts:
        summary = f"{diagnosis.get('conditions', [{}])[0].get('name', '')}. {diagnosis.get('action', '')}".strip()
        file_path = synthesize_speech(elevenlabs_key, summary, args.out, args.language)
        if file_path is None:
            print("TTS skipped (missing ELEVENLABS_KEY or empty summary)")
        else:
            print(f"TTS written to: {file_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
