from __future__ import annotations

import time
from typing import Any, Dict, List

import requests

EXA_SEARCH_URL = "https://api.exa.ai/search"

DEFAULT_INCLUDE_DOMAINS = [
    "mayoclinic.org",
    "webmd.com",
    "vinmec.com",
    "healthline.com",
]


def search_medical_sources(exa_key: str, query: str, num_results: int = 5) -> List[Dict[str, Any]]:
    if not exa_key or not query.strip():
        return []

    payload = {
        "query": query,
        "num_results": num_results,
        "includeDomains": DEFAULT_INCLUDE_DOMAINS,
    }

    headers = {
        "x-api-key": exa_key,
        "Content-Type": "application/json",
    }

    last_error: Exception | None = None
    for attempt in range(3):
        try:
            response = requests.post(
                EXA_SEARCH_URL,
                headers=headers,
                json=payload,
                timeout=45,
            )
            response.raise_for_status()
            data = response.json()
            return data.get("results", [])
        except requests.RequestException as exc:
            last_error = exc
            if attempt < 2:
                time.sleep(1 + attempt)

    if last_error is not None:
        raise last_error
    return []
