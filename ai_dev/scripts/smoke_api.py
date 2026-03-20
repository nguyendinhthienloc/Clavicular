from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict

import requests


ROOT = Path(__file__).resolve().parents[1]
REQUESTS_DIR = ROOT / "requests"


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return data


def post_json(base_url: str, route: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    url = f"{base_url.rstrip('/')}{route}"
    response = requests.post(url, json=payload, timeout=60)
    response.raise_for_status()
    return response.json()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Cross-platform API smoke test")
    parser.add_argument("--base-url", default="http://127.0.0.1:8016")
    parser.add_argument("--diagnose-file", default=str(REQUESTS_DIR / "diagnose.sample.json"))
    parser.add_argument("--sources-file", default=str(REQUESTS_DIR / "sources.sample.json"))
    parser.add_argument("--skip-sources", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        health = requests.get(f"{args.base_url.rstrip('/')}/health", timeout=15)
        health.raise_for_status()
        print("[OK] /health", health.json())

        diagnose_payload = load_json(Path(args.diagnose_file))
        diagnose_res = post_json(args.base_url, "/api/diagnose", diagnose_payload)
        severity = diagnose_res.get("data", {}).get("severity")
        print(f"[OK] /api/diagnose severity={severity}")

        if not args.skip_sources:
            sources_payload = load_json(Path(args.sources_file))
            sources_res = post_json(args.base_url, "/api/sources", sources_payload)
            count = len(sources_res.get("results", []))
            print(f"[OK] /api/sources results={count}")

        return 0
    except requests.HTTPError as exc:
        body = exc.response.text if exc.response is not None else ""
        print(f"[HTTP ERROR] {exc}\n{body}", file=sys.stderr)
        return 2
    except Exception as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
