from __future__ import annotations

import os
from pathlib import Path
from dotenv import load_dotenv


def load_env() -> None:
    """Load root .env for local development."""
    root_env = Path(__file__).resolve().parents[2] / ".env"
    load_dotenv(root_env, override=False)


def get_env(name: str, default: str = "") -> str:
    return os.getenv(name, default)
