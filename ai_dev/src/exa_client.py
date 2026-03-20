from __future__ import annotations

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

    response = requests.post(
        EXA_SEARCH_URL,
        headers={
            "x-api-key": exa_key,
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=45,
    )
    response.raise_for_status()

    data = response.json()
    return data.get("results", [])
