from __future__ import annotations

from typing import Any, Dict, List

import requests


PLACES_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

CONDITION_KEYWORDS = {
    "muscle": "orthopedic physiotherapy sports medicine",
    "chest": "cardiology heart hospital emergency",
    "abdomen": "gastroenterology general hospital",
    "head": "neurology general clinic",
    "back": "orthopedic spine physiotherapy",
    "joint": "orthopedic rheumatology clinic",
    "skin": "dermatology clinic",
    "default": "clinic hospital",
}


def get_keyword_for_condition(condition_name: str) -> str:
    name_lower = (condition_name or "").lower()
    if any(w in name_lower for w in ["muscle", "strain", "sprain", "tendon", "ligament"]):
        return CONDITION_KEYWORDS["muscle"]
    if any(w in name_lower for w in ["chest", "heart", "cardiac", "angina"]):
        return CONDITION_KEYWORDS["chest"]
    if any(w in name_lower for w in ["abdomen", "stomach", "gastro", "bowel"]):
        return CONDITION_KEYWORDS["abdomen"]
    if any(w in name_lower for w in ["head", "migraine", "neuro", "brain"]):
        return CONDITION_KEYWORDS["head"]
    if any(w in name_lower for w in ["back", "spine", "disc", "lumbar"]):
        return CONDITION_KEYWORDS["back"]
    if any(w in name_lower for w in ["joint", "knee", "hip", "shoulder", "arthritis"]):
        return CONDITION_KEYWORDS["joint"]
    if any(w in name_lower for w in ["skin", "rash", "derma"]):
        return CONDITION_KEYWORDS["skin"]
    return CONDITION_KEYWORDS["default"]


def find_nearby_clinics(
    lat: float,
    lng: float,
    condition_name: str,
    google_key: str,
    radius_meters: int = 3000,
    max_results: int = 3,
) -> List[Dict[str, Any]]:
    if not google_key or lat is None or lng is None:
        return []

    keyword = get_keyword_for_condition(condition_name)

    try:
        response = requests.get(
            PLACES_URL,
            params={
                "location": f"{lat},{lng}",
                "radius": radius_meters,
                "type": "hospital",
                "keyword": keyword,
                "key": google_key,
            },
            timeout=10,
        )
        response.raise_for_status()
        results = response.json().get("results", [])

        clinics: List[Dict[str, Any]] = []
        for result in results[:max_results]:
            loc = result.get("geometry", {}).get("location", {})
            clinics.append(
                {
                    "name": result.get("name"),
                    "address": result.get("vicinity"),
                    "rating": result.get("rating"),
                    "open_now": result.get("opening_hours", {}).get("open_now"),
                    "maps_url": (
                        "https://www.google.com/maps/search/?api=1"
                        f"&query={loc.get('lat')},{loc.get('lng')}"
                    ),
                }
            )
        return clinics
    except Exception:
        # Fail silently so diagnosis remains available even if Places fails.
        return []