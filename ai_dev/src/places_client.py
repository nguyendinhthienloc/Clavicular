from __future__ import annotations

from typing import Any, Dict, List

import requests


PLACES_URL = "https://places-api.foursquare.com/places/search"

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
    foursquare_key: str,
    radius_meters: int = 3000,
    max_results: int = 3,
) -> List[Dict[str, Any]]:
    if not foursquare_key or lat is None or lng is None:
        return []

    keyword = get_keyword_for_condition(condition_name)

    try:
        response = requests.get(
            PLACES_URL,
            headers={
                "Authorization": f"Bearer {foursquare_key}",
                "Accept": "application/json",
                "X-Places-Api-Version": "2025-06-17",
            },
            params={
                "ll": f"{lat},{lng}",
                "radius": radius_meters,
                "query": keyword,
                "categories": "15014,15007",  # hospitals, clinics
                "limit": max_results,
            },
            timeout=10,
        )
        response.raise_for_status()
        results = response.json().get("results", [])

        clinics: List[Dict[str, Any]] = []
        for result in results[:max_results]:
            # Handle new v3 API field format (direct latitude/longitude)
            fsq_lat = result.get("latitude") or result.get("geocodes", {}).get("main", {}).get("latitude")
            fsq_lng = result.get("longitude") or result.get("geocodes", {}).get("main", {}).get("longitude")
            
            # Get address from new format or fallback to old
            address = result.get("location", {}).get("formatted_address", "")
            if not address:
                address = result.get("formatted_address", "")
            
            clinics.append(
                {
                    "name": result.get("name"),
                    "address": address,
                    "lat": fsq_lat,
                    "lon": fsq_lng,
                    "rating": result.get("rating"),
                    "open_now": result.get("hours", {}).get("open_now"),
                    "maps_url": (
                        "https://www.google.com/maps/search/?api=1"
                        f"&query={fsq_lat},{fsq_lng}"
                    ),
                }
            )
        return clinics
    except Exception as e:
        # Fail silently so diagnosis remains available even if Places fails.
        print(f"[FOURSQUARE ERROR] {type(e).__name__}: {str(e)}")
        return []