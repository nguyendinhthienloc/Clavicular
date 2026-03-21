from __future__ import annotations

import logging
from typing import Any, Dict, List, Literal, Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

try:
    from .config import get_env, load_env
    from .exa_client import search_medical_sources
    from .fal_client import generate_body_image as generate_fal_image
    from .gemini_client import generate_body_image
    from .elevenlabs_client import synthesize_speech
    from .openrouter_client import call_diagnosis
    from .openai_chat_client import DEFAULT_CHAT_MODEL, chat_with_clinician
    from .places_client import find_nearby_clinics
except ImportError:
    from config import get_env, load_env
    from exa_client import search_medical_sources
    from fal_client import generate_body_image as generate_fal_image
    from gemini_client import generate_body_image
    from elevenlabs_client import synthesize_speech
    from openrouter_client import call_diagnosis
    from openai_chat_client import DEFAULT_CHAT_MODEL, chat_with_clinician
    from places_client import find_nearby_clinics


class DiagnoseRequest(BaseModel):
    user_message: Optional[str] = None
    query: Optional[str] = None
    region_name: Optional[str] = None
    language: Literal["en", "vi"] = "en"
    lat: Optional[float] = None
    lng: Optional[float] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    coordinates: Optional[Dict[str, float]] = None


class AnalyzeRequest(BaseModel):
    input_text: Optional[str] = None
    user_message: Optional[str] = None
    query: Optional[str] = None
    language: Literal["en", "vi"] = "en"
    num_results: int = Field(default=5, ge=1, le=10)


class TTSRequest(BaseModel):
    text: str = Field(min_length=1)
    language: Literal["en", "vi"] = "en"
    output_file: str = "ai_dev/output/tts_output.mp3"


class SourcesRequest(BaseModel):
    query: Optional[str] = None
    user_message: Optional[str] = None
    num_results: int = Field(default=5, ge=1, le=10)


class ImageRequest(BaseModel):
    region_name: str = Field(min_length=1)


class EchoRequest(BaseModel):
    text: str = Field(min_length=1)


class ChatHistoryMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    language: Literal["en", "vi"] = "en"
    history: List[ChatHistoryMessage] = Field(default_factory=list)
    model: str = DEFAULT_CHAT_MODEL
    temperature: float = Field(default=0.4, ge=0.0, le=1.5)


app = FastAPI(title="BodyCheck Person 3 API", version="1.0.0")
logger = logging.getLogger("ai_dev.server")


def _first_non_empty(*values: Optional[str]) -> Optional[str]:
    for value in values:
        if value and value.strip():
            return value.strip()
    return None


def _parse_cors_origins(raw: Optional[str]) -> list[str]:
    if not raw or raw.strip() == "*":
        return ["*"]
    return [part.strip() for part in raw.split(",") if part.strip()]


def _resolve_coords(payload: DiagnoseRequest) -> tuple[Optional[float], Optional[float]]:
    lat = payload.lat if payload.lat is not None else payload.latitude
    lng = payload.lng if payload.lng is not None else payload.longitude

    if payload.coordinates:
        if lat is None:
            lat = payload.coordinates.get("lat", payload.coordinates.get("latitude"))
        if lng is None:
            lng = payload.coordinates.get("lng", payload.coordinates.get("longitude"))

    return lat, lng


MUSCLE_MAP = {
    "Rectus_Abdominis_L": "Left rectus abdominis (lower abdomen)",
    "Rectus_Abdominis_R": "Right rectus abdominis (lower abdomen)",
    "Deltoid_L": "Left deltoid (shoulder muscle)",
    "Deltoid_R": "Right deltoid (shoulder muscle)",
    "Biceps_Brachii_L": "Left biceps (upper arm)",
    "Biceps_Brachii_R": "Right biceps (upper arm)",
    "Gastrocnemius_L": "Left calf muscle",
    "Gastrocnemius_R": "Right calf muscle",
    "Trapezius": "Trapezius (upper back and neck muscle)",
    "Latissimus_Dorsi_L": "Left latissimus dorsi (mid back)",
    "Latissimus_Dorsi_R": "Right latissimus dorsi (mid back)",
}


def clean_muscle_name(raw: str) -> str:
    if raw in MUSCLE_MAP:
        return MUSCLE_MAP[raw]
    return raw.replace("_", " ").strip()


@app.exception_handler(RequestValidationError)
async def request_validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    logger.warning("Validation error on %s: %s", request.url.path, exc)
    return JSONResponse(
        status_code=400,
        content={
            "success": False,
            "error": "Invalid request payload",
            "path": request.url.path,
            "hint": "Send a valid JSON object with Content-Type: application/json. Use ai_dev/requests/*.sample.json as templates.",
            "details": exc.errors(),
        },
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled server error on %s", request.url.path)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "Internal server error",
            "path": request.url.path,
        },
    )

# Keep open CORS for hackathon integration speed.
cors_origins = _parse_cors_origins(get_env("CORS_ALLOW_ORIGINS", "*"))
allow_credentials = cors_origins != ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    load_env()


@app.get("/health")
def health() -> Dict[str, Any]:
    return {"ok": True, "service": "person3-ai-api"}


@app.get("/")
def root() -> Dict[str, Any]:
        return {
                "ok": True,
                "service": "person3-ai-api",
                "message": "Server is running. Use /demo for a quick UI or /docs for Swagger.",
                "endpoints": [
                        "GET /health",
                        "POST /api/echo",
            "POST /api/chat",
                        "POST /api/diagnose",
                        "POST /api/sources",
                    "POST /api/analyze",
                        "POST /api/image",
                ],
        }


@app.get("/demo", response_class=HTMLResponse)
def demo() -> str:
        return """
<!doctype html>
<html>
    <head>
        <meta charset='utf-8' />
        <meta name='viewport' content='width=device-width, initial-scale=1' />
        <title>Person 3 API Demo</title>
        <style>
            body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; max-width: 900px; }
            textarea, input, select { width: 100%; margin-top: 6px; margin-bottom: 10px; }
            textarea { min-height: 100px; }
            button { margin-right: 8px; margin-bottom: 8px; }
            pre { background: #f5f5f5; padding: 10px; border-radius: 6px; overflow: auto; }
        </style>
    </head>
    <body>
        <h2>Person 3 FastAPI Demo</h2>
        <p>Use this page to verify API features quickly.</p>

        <label>Text (Echo test)</label>
        <input id='echoText' value='hello team' />
        <button onclick='echoTest()'>Test /api/echo</button>

        <hr />

        <label>Diagnose message</label>
        <textarea id='diagMsg'>Body region: Chest\nPain type: pressure\nDuration: 30 minutes\nSeverity: 9\nOther: left arm pain</textarea>
        <label>Language</label>
        <select id='lang'>
            <option value='en'>en</option>
            <option value='vi'>vi</option>
        </select>
        <label>Location (optional for nearby clinics)</label>
        <input id='lat' type='number' step='any' placeholder='Latitude' />
        <input id='lng' type='number' step='any' placeholder='Longitude' />
        <button onclick='useMyLocation()'>Use My Location</button>
        <button onclick='diagnoseTest()'>Test /api/diagnose</button>

        <hr />

        <label>Sources query</label>
        <input id='srcQuery' value='appendicitis symptoms' />
        <button onclick='sourcesTest()'>Test /api/sources</button>

        <hr />

        <label>Image region (optional)</label>
        <input id='region' value='lower right abdomen' />
        <button onclick='imageTest()'>Test /api/image</button>

        <h3>Response</h3>
        <pre id='out'>Ready</pre>

        <script>
            const out = document.getElementById('out');
            async function call(path, payload) {
                const res = await fetch(path, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const text = await res.text();
                let data = text;
                try { data = JSON.parse(text); } catch (_) {}
                out.textContent = JSON.stringify({ status: res.status, ok: res.ok, data }, null, 2);
            }
            function echoTest() {
                const text = document.getElementById('echoText').value;
                call('/api/echo', { text });
            }
            function diagnoseTest() {
                const user_message = document.getElementById('diagMsg').value;
                const language = document.getElementById('lang').value;
                const latRaw = document.getElementById('lat').value.trim();
                const lngRaw = document.getElementById('lng').value.trim();
                const payload = { user_message, language };
                if (latRaw && lngRaw) {
                    payload.lat = Number(latRaw);
                    payload.lng = Number(lngRaw);
                }
                call('/api/diagnose', payload);
            }
            function useMyLocation() {
                if (!navigator.geolocation) {
                    out.textContent = JSON.stringify({ error: 'Geolocation is not supported by this browser.' }, null, 2);
                    return;
                }
                out.textContent = JSON.stringify({ status: 'Requesting geolocation permission...' }, null, 2);
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        document.getElementById('lat').value = String(position.coords.latitude);
                        document.getElementById('lng').value = String(position.coords.longitude);
                        out.textContent = JSON.stringify({
                            status: 'Location captured',
                            lat: position.coords.latitude,
                            lng: position.coords.longitude,
                            accuracy_meters: position.coords.accuracy
                        }, null, 2);
                    },
                    (err) => {
                        out.textContent = JSON.stringify({
                            error: 'Unable to get location',
                            code: err.code,
                            message: err.message
                        }, null, 2);
                    },
                    { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
                );
            }
            function sourcesTest() {
                const query = document.getElementById('srcQuery').value;
                call('/api/sources', { query, num_results: 3 });
            }
            function imageTest() {
                const region_name = document.getElementById('region').value;
                call('/api/image', { region_name });
            }
        </script>
    </body>
</html>
"""


@app.post("/api/echo")
def echo(payload: EchoRequest) -> Dict[str, Any]:
        return {
                "success": True,
                "input": payload.text,
                "output": payload.text,
                "length": len(payload.text),
        }


@app.post("/api/chat")
def chat(payload: ChatRequest) -> Dict[str, Any]:
    openai_key = get_env("OPENAI_API_KEY")
    if not openai_key:
        raise HTTPException(status_code=400, detail="Missing OPENAI_API_KEY")

    try:
        history = [item.model_dump() for item in payload.history]
        reply, used_model = chat_with_clinician(
            openai_key=openai_key,
            user_message=payload.message,
            language=payload.language,
            history=history,
            model=payload.model,
            temperature=payload.temperature,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"OpenAI chat failed: {exc}") from exc

    return {
        "success": True,
        "reply": reply,
        "model": used_model,
        "roleplay": "trained_clinician",
    }


@app.post("/api/diagnose")
def diagnose(payload: DiagnoseRequest) -> Dict[str, Any]:
    if payload.region_name and payload.region_name.strip():
        cleaned = clean_muscle_name(payload.region_name)
        user_message = f"Body region: {cleaned}\nPain type: not specified\nSeverity: unknown"
    else:
        user_message = _first_non_empty(payload.user_message, payload.query)

    if not user_message:
        raise HTTPException(status_code=400, detail="Missing user_message, query, or region_name")

    openrouter_key = get_env("OPENROUTER_KEY")
    diagnosis = call_diagnosis(openrouter_key, user_message, payload.language)

    clinics = []
    lat, lng = _resolve_coords(payload)
    if lat is not None and lng is not None:
        top_condition = diagnosis.get("conditions", [{}])[0].get("name", "")
        foursquare_key = get_env("FOURSQUARE_API_KEY") or get_env("GOOGLE_PLACES_KEY")
        clinics = find_nearby_clinics(
            lat=lat,
            lng=lng,
            condition_name=top_condition,
            foursquare_key=foursquare_key,
        )

    return {"success": True, "data": diagnosis, "clinics": clinics}


@app.post("/api/tts")
def tts(payload: TTSRequest) -> Dict[str, Any]:
    elevenlabs_key = get_env("ELEVENLABS_KEY")
    try:
        output = synthesize_speech(
            elevenlabs_key=elevenlabs_key,
            text=payload.text,
            output_file=payload.output_file,
            language=payload.language,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"TTS failed: {exc}") from exc

    if output is None:
        raise HTTPException(status_code=400, detail="Missing ELEVENLABS_KEY or text")

    return {"success": True, "audio_path": str(output)}


@app.post("/api/sources")
def sources(payload: SourcesRequest) -> Dict[str, Any]:
    query = _first_non_empty(payload.query, payload.user_message)
    if not query:
        raise HTTPException(status_code=400, detail="Missing query (or user_message)")

    exa_key = get_env("EXA_KEY")
    if not exa_key:
        raise HTTPException(status_code=400, detail="Missing EXA_KEY")

    try:
        results = search_medical_sources(exa_key, query, payload.num_results)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Exa failed: {exc}") from exc

    return {"success": True, "results": results}


@app.post("/api/analyze")
def analyze(payload: AnalyzeRequest) -> Dict[str, Any]:
    text_input = _first_non_empty(payload.input_text, payload.user_message, payload.query)
    if not text_input:
        raise HTTPException(status_code=400, detail="Missing input_text (or user_message/query)")

    openrouter_key = get_env("OPENROUTER_KEY")
    diagnosis = call_diagnosis(openrouter_key, text_input, payload.language)

    exa_key = get_env("EXA_KEY")
    sources_results = []
    sources_error = None
    if exa_key:
        try:
            sources_results = search_medical_sources(exa_key, text_input, payload.num_results)
        except Exception as exc:
            sources_error = f"Exa failed: {exc}"
    else:
        sources_error = "Missing EXA_KEY"

    return {
        "success": True,
        "input": text_input,
        "diagnosis": diagnosis,
        "sources": sources_results,
        "sources_error": sources_error,
    }


@app.post("/api/image")
def image(payload: ImageRequest) -> Dict[str, Any]:
    gemini_key = get_env("GEMINI_KEY")
    fal_key = get_env("FAL_KEY")

    if not gemini_key and not fal_key:
        raise HTTPException(status_code=400, detail="Missing GEMINI_KEY and FAL_KEY")

    image_data = None
    provider = None
    try:
        if gemini_key:
            image_data = generate_body_image(payload.region_name, gemini_key)
            if image_data:
                provider = "gemini"
    except Exception as exc:
        logger.warning("Gemini image generation failed: %s", exc)

    if not image_data and fal_key:
        try:
            prompt = (
                f"Medical illustration of the human {payload.region_name}, highlighted in red, "
                "clean white background, anatomical diagram style, no text labels"
            )
            image_data = generate_fal_image(fal_key=fal_key, prompt=prompt)
            if image_data:
                provider = "fal"
        except Exception as exc:
            logger.warning("FAL image generation failed: %s", exc)

    if not image_data:
        raise HTTPException(status_code=502, detail="Image generation failed on all providers")

    return {"success": True, "image": image_data, "provider": provider}
