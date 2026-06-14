# Whisper STT Integration Plan
## Voice Input: User speaks symptoms → text → Claude diagnosis
### AI-dev (Python) + Flutter Frontend

---

## Overview

User taps mic in Flutter → audio recorded → sent to your FastAPI server →
server sends to OpenAI Whisper → text returned → auto-fills symptom input →
sent to Claude for diagnosis.

```
Flutter mic button
      ↓
Record audio (webm/m4a)
      ↓
POST /api/transcribe (your server)
      ↓
OpenAI Whisper API
      ↓
Text returned to Flutter
      ↓
Auto-fill symptom box
      ↓
POST /api/diagnose as normal
```

---

## Prerequisites

- OpenAI API key (`OPENAI_KEY`) — you have $100 credits
- Add to `.env`:
```
OPENAI_KEY=sk-...
```

---

## PART 1: AI-Dev Side (20 min)

### Step 1: Install dependency

```bash
pip install python-multipart
```

Required for FastAPI to accept file uploads.

### Step 2: Create `whisper_client.py`

Create `ai_dev/src/whisper_client.py`:

```python
from __future__ import annotations
from typing import Optional
import requests


WHISPER_URL = "https://api.openai.com/v1/audio/transcriptions"
SUPPORTED_LANGUAGES = {"en": "en", "vi": "vi"}


def transcribe_audio(
    audio_bytes: bytes,
    openai_key: str,
    language: str = "en",
    filename: str = "audio.webm",
) -> Optional[str]:
    """
    Send audio bytes to OpenAI Whisper and return transcribed text.
    Returns None if transcription fails.
    """
    if not openai_key or not audio_bytes:
        return None

    lang_code = SUPPORTED_LANGUAGES.get(language, "en")

    try:
        response = requests.post(
            WHISPER_URL,
            headers={
                "Authorization": f"Bearer {openai_key}",
            },
            files={
                "file": (filename, audio_bytes, "audio/webm"),
            },
            data={
                "model": "whisper-1",
                "language": lang_code,
                "response_format": "text",   # returns plain text, not JSON
            },
            timeout=30,
        )
        response.raise_for_status()
        return response.text.strip()

    except Exception as e:
        print(f"[whisper] transcription error: {e}")
        return None
```

---

### Step 3: Add /api/transcribe to server.py

Add import at top of `server.py`:
```python
from fastapi import UploadFile, File, Form
from .whisper_client import transcribe_audio
```

Add the endpoint:
```python
@app.post("/api/transcribe")
async def transcribe(
    file: UploadFile = File(...),
    language: str = Form(default="en"),
) -> Dict[str, Any]:
    """
    Accepts an audio file upload and returns transcribed text.
    Supports English and Vietnamese.
    """
    openai_key = get_env("OPENAI_KEY")
    if not openai_key:
        raise HTTPException(status_code=400, detail="Missing OPENAI_KEY")

    # read audio bytes
    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

    # validate size — Whisper max is 25MB
    if len(audio_bytes) > 25 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Audio file too large (max 25MB)")

    text = transcribe_audio(
        audio_bytes=audio_bytes,
        openai_key=openai_key,
        language=language,
        filename=file.filename or "audio.webm",
    )

    if not text:
        raise HTTPException(status_code=502, detail="Transcription failed")

    return {"success": True, "text": text}
```

---

### Step 4: Test with curl

Record a short audio file first (or use any .mp3/.webm you have):

```bash
curl -X POST http://localhost:8016/api/transcribe \
  -F "file=@test_audio.webm;type=audio/webm" \
  -F "language=en"
```

Expected response:
```json
{
  "success": true,
  "text": "I have sharp pain in my lower right abdomen with fever and nausea"
}
```

Vietnamese test:
```bash
curl -X POST http://localhost:8016/api/transcribe \
  -F "file=@test_audio.webm;type=audio/webm" \
  -F "language=vi"
```

Expected response:
```json
{
  "success": true,
  "text": "Tôi bị đau nhói ở bụng dưới bên phải kèm theo sốt và buồn nôn"
}
```

---

### Step 5: Update demo UI in server.py

Add a mic test section to your `/demo` HTML page.
Find the `<body>` section and add:

```html
<hr />
<label>Voice input test (record then transcribe)</label><br/>
<button onclick="startRec()" id="recBtn">🎙 Start recording</button>
<button onclick="stopRec()" id="stopBtn" disabled>⏹ Stop + transcribe</button>
<div id="transcribeOut" style="margin-top:8px;color:green;"></div>

<script>
let mediaRecorder, chunks = [];

async function startRec() {
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  mediaRecorder = new MediaRecorder(stream);
  chunks = [];
  mediaRecorder.ondataavailable = e => chunks.push(e.data);
  mediaRecorder.start();
  document.getElementById('recBtn').disabled = true;
  document.getElementById('stopBtn').disabled = false;
}

async function stopRec() {
  mediaRecorder.stop();
  mediaRecorder.onstop = async () => {
    const blob = new Blob(chunks, { type: 'audio/webm' });
    const formData = new FormData();
    formData.append('file', blob, 'audio.webm');
    formData.append('language', document.getElementById('lang').value);

    const res = await fetch('/api/transcribe', { method: 'POST', body: formData });
    const data = await res.json();
    document.getElementById('transcribeOut').textContent =
      data.text ? '✓ ' + data.text : '✗ ' + JSON.stringify(data);

    // also auto-fill the diagnose textarea
    if (data.text) document.getElementById('diagMsg').value = data.text;
  };
  document.getElementById('recBtn').disabled = false;
  document.getElementById('stopBtn').disabled = true;
}
</script>
```

Now you can test voice → transcription → diagnosis all from `/demo`.

---

## PART 2: Flutter Frontend Side (25 min)

### Step 1: Add dependencies to pubspec.yaml

```yaml
dependencies:
  record: ^5.1.0          # audio recording
  path_provider: ^2.1.0   # temp file storage
  dio: ^5.3.0             # already have this
```

Run:
```bash
flutter pub get
```

### Step 2: Add permissions

**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>BodyCheck needs mic access to transcribe your symptoms</string>
```

**Web** — nothing needed, browser asks automatically.

---

### Step 3: Create voice_input.dart

Create `lib/voice_input.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VoiceInputButton extends StatefulWidget {
  final String language;                    // "en" or "vi"
  final String apiBaseUrl;                  // your server IP
  final Function(String text) onTranscribed; // callback with result text

  const VoiceInputButton({
    super.key,
    required this.language,
    required this.apiBaseUrl,
    required this.onTranscribed,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isLoading = false;
  String? _audioPath;

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    _audioPath = '${dir.path}/symptom_audio.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _audioPath!,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopAndTranscribe() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isLoading = true;
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _audioPath!,
          filename: 'audio.m4a',
        ),
        'language': widget.language,
      });

      final response = await dio.post(
        '${widget.apiBaseUrl}/api/transcribe',
        data: formData,
      );

      final text = response.data['text'] as String?;
      if (text != null && text.isNotEmpty) {
        widget.onTranscribed(text);
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: Icon(
        _isRecording ? Icons.stop_circle : Icons.mic,
        color: _isRecording ? Colors.red : Colors.blue,
        size: 28,
      ),
      tooltip: _isRecording ? 'Stop recording' : 'Speak your symptoms',
      onPressed: _isRecording ? _stopAndTranscribe : _startRecording,
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
```

---

### Step 4: Use it in viewport_chat.dart

Add the mic button next to the symptom text field:

```dart
import 'voice_input.dart';

// inside your chat input row:
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: 'Describe your symptoms...',
        ),
      ),
    ),
    VoiceInputButton(
      language: _currentLanguage,       // "en" or "vi"
      apiBaseUrl: AppConfig.aiApiTunnel,
      onTranscribed: (text) {
        // auto-fill the text field with transcribed text
        setState(() {
          _textController.text = text;
        });
      },
    ),
    IconButton(
      icon: const Icon(Icons.send),
      onPressed: _sendMessage,
    ),
  ],
)
```

---

### Step 5: Test end to end in Flutter

1. Run Flutter app
2. Click a muscle on 3D model
3. Tap mic button 🎙
4. Say: "sharp pain, started 2 hours ago, also have fever"
5. Tap stop ⏹
6. Text auto-fills in symptom box
7. Tap send
8. Diagnosis appears

---

## Full flow summary

```
Tap 🎙 → recording starts (red indicator)
      ↓
Speak symptoms in English or Vietnamese
      ↓
Tap ⏹ → audio saved to temp file
      ↓
POST /api/transcribe (multipart audio file)
      ↓
Whisper returns text
      ↓
Text auto-fills symptom box in Flutter
      ↓
User reviews text (can edit if needed)
      ↓
Tap send → POST /api/diagnose as normal
      ↓
Diagnosis card appears
```

---

## Cost estimate

Whisper costs $0.006 per minute of audio.
A 10-second symptom description = ~$0.001 per transcription.
With $100 OpenAI credits = 100,000 transcriptions.
You will never run out.

---

## Files changed summary

| File | Change | Who |
|---|---|---|
| `.env` | Add `OPENAI_KEY` | You |
| `ai_dev/src/whisper_client.py` | New file | You |
| `ai_dev/src/server.py` | Add `/api/transcribe` endpoint | You |
| Flutter `pubspec.yaml` | Add `record`, `path_provider` | Flutter friend |
| Flutter `AndroidManifest.xml` | Add mic permission | Flutter friend |
| Flutter `ios/Info.plist` | Add mic usage description | Flutter friend |
| Flutter `lib/voice_input.dart` | New widget | Flutter friend |
| Flutter `lib/viewport_chat.dart` | Add VoiceInputButton | Flutter friend |

---

## If audio format causes issues

Whisper supports: `mp3, mp4, mpeg, mpga, m4a, wav, webm`
If Flutter records in a format Whisper rejects, change the encoder:

```dart
// try wav if m4a fails
RecordConfig(encoder: AudioEncoder.wav)
```

And update the filename in FormData:
```dart
filename: 'audio.wav'
```
