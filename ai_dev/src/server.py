from __future__ import annotations

from typing import Any, Dict, Literal, Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

try:
    from .config import get_env, load_env
    from .exa_client import search_medical_sources
    from .gemini_client import generate_body_image
    from .elevenlabs_client import synthesize_speech
    from .openrouter_client import call_diagnosis
except ImportError:
    from config import get_env, load_env
    from exa_client import search_medical_sources
    from gemini_client import generate_body_image
    from elevenlabs_client import synthesize_speech
    from openrouter_client import call_diagnosis


class DiagnoseRequest(BaseModel):
    user_message: Optional[str] = None
    query: Optional[str] = None
    language: Literal["en", "vi"] = "en"


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


app = FastAPI(title="BodyCheck Person 3 API", version="1.0.0")


def _first_non_empty(*values: Optional[str]) -> Optional[str]:
    for value in values:
        if value and value.strip():
            return value.strip()
    return None


@app.exception_handler(RequestValidationError)
async def request_validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
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

# Keep open CORS for hackathon integration speed.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
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
                call('/api/diagnose', { user_message, language });
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


@app.post("/api/diagnose")
def diagnose(payload: DiagnoseRequest) -> Dict[str, Any]:
    user_message = _first_non_empty(payload.user_message, payload.query)
    if not user_message:
        raise HTTPException(status_code=400, detail="Missing user_message (or query)")

    openrouter_key = get_env("OPENROUTER_KEY")
    diagnosis = call_diagnosis(openrouter_key, user_message, payload.language)
    return {"success": True, "data": diagnosis}


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
    if not gemini_key:
        raise HTTPException(status_code=400, detail="Missing GEMINI_KEY")

    try:
        image_data = generate_body_image(payload.region_name, gemini_key)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Gemini image failed: {exc}") from exc

    if not image_data:
        raise HTTPException(status_code=502, detail="Image generation failed")

    return {"success": True, "image": image_data}
