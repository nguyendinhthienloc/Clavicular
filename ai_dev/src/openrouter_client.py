from __future__ import annotations

import json
from typing import Any, Dict

import requests

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
FALLBACK_MODEL = "openai/gpt-4o-mini"

SYSTEM_EN = """You are a medical triage AI. Analyze the patient's body region and symptoms.
Respond ONLY with raw valid JSON. No markdown, no backticks, no explanation.

{
  \"conditions\": [
    { \"name\": \"string\", \"likelihood\": \"High|Medium|Low\", \"explanation\": \"max 20 words\" }
  ],
  \"severity\": \"Low|Medium|High|Emergency\",
  \"action\": \"One clear sentence on what the patient should do.\",
  \"home_tips\": [\"tip 1\", \"tip 2\"],
  \"warning_signs\": [\"sign 1\"],
  \"disclaimer\": \"This is AI information only, not medical advice. For emergencies call 115.\"
}

Rules:
- 2 to 3 conditions, most likely first
- \"Emergency\" only for life-threatening signs (chest pain radiating to arm, appendicitis, stroke)
- Severity rubric:
    - \"Low\": mild symptoms, no red flags, manageable at home
    - \"Medium\": needs pharmacy or GP visit within 1 to 2 days
    - \"High\": needs same-day doctor visit
    - \"Emergency\": life-threatening, call 115 now
- Keep explanations under 20 words
- Always include the disclaimer field exactly as shown"""

SYSTEM_VI = """Bạn là AI phân loại y tế. Phân tích vùng cơ thể và triệu chứng.
Chỉ trả lời bằng JSON thuần túy, không markdown, không backtick.

{
  \"conditions\": [
    { \"name\": \"string\", \"likelihood\": \"High|Medium|Low\", \"explanation\": \"tối đa 20 từ\" }
  ],
  \"severity\": \"Low|Medium|High|Emergency\",
  \"action\": \"Một câu rõ ràng về việc cần làm.\",
  \"home_tips\": [\"mẹo 1\", \"mẹo 2\"],
  \"warning_signs\": [\"dấu hiệu 1\"],
  \"disclaimer\": \"Đây chỉ là thông tin AI, không phải lời khuyên y tế. Cấp cứu gọi 115.\"
}

Bạn MUST trả lời hoàn toàn bằng Tiếng Việt."""


def fallback_diagnosis(language: str) -> Dict[str, Any]:
    if language == "vi":
        return {
            "conditions": [
                {
                    "name": "Không thể phân tích",
                    "likelihood": "Low",
                    "explanation": "Vui lòng thử lại hoặc tham khảo bác sĩ trực tiếp.",
                }
            ],
            "severity": "Medium",
            "action": "Vui lòng tham khảo bác sĩ hoặc cơ sở y tế gần nhất.",
            "home_tips": ["Nghỉ ngơi và theo dõi triệu chứng", "Ghi lại thời gian và mức độ đau"],
            "warning_signs": ["Đau tăng đột ngột", "Khó thở", "Mất ý thức"],
            "disclaimer": "Đây chỉ là thông tin AI, không phải lời khuyên y tế. Cấp cứu gọi 115.",
        }

    return {
        "conditions": [
            {
                "name": "Analysis unavailable",
                "likelihood": "Low",
                "explanation": "Please try again or consult a doctor directly.",
            }
        ],
        "severity": "Medium",
        "action": "Please consult a doctor or visit your nearest clinic.",
        "home_tips": ["Rest and monitor your symptoms"],
        "warning_signs": ["Sudden worsening", "Difficulty breathing"],
        "disclaimer": "This is AI information only, not medical advice. For emergencies call 115.",
    }


def _parse_model_content(raw_text: str) -> Dict[str, Any]:
    cleaned = (
        raw_text.replace("```json", "").replace("```", "").strip()
    )
    parsed = json.loads(cleaned)
    if not parsed.get("conditions") or not parsed.get("severity") or not parsed.get("action"):
        raise ValueError("Bad JSON shape")
    return parsed


def _request_diagnosis(openrouter_key: str, model: str, system_prompt: str, user_message: str) -> Dict[str, Any]:
    response = requests.post(
        OPENROUTER_URL,
        headers={
            "Authorization": f"Bearer {openrouter_key}",
            "Content-Type": "application/json",
            "X-Title": "BodyCheck - LotusHacks 2026",
        },
        json={
            "model": model,
            "max_tokens": 900,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
        },
        timeout=45,
    )
    response.raise_for_status()
    data = response.json()
    raw = data.get("choices", [{}])[0].get("message", {}).get("content", "")
    return _parse_model_content(raw)


def call_diagnosis(openrouter_key: str, user_message: str, language: str = "en") -> Dict[str, Any]:
    selected_language = "vi" if language == "vi" else "en"
    primary_model = "qwen/qwen-2.5-72b-instruct" if selected_language == "vi" else "anthropic/claude-3.5-sonnet"
    system_prompt = SYSTEM_VI if selected_language == "vi" else SYSTEM_EN

    if not openrouter_key:
        return fallback_diagnosis(selected_language)

    try:
        return _request_diagnosis(openrouter_key, primary_model, system_prompt, user_message)
    except Exception:
        try:
            return _request_diagnosis(openrouter_key, FALLBACK_MODEL, system_prompt, user_message)
        except Exception:
            return fallback_diagnosis(selected_language)
