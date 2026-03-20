const ELEVENLABS_KEY = window.ENV?.ELEVENLABS_KEY || '';
const VOICE_ID = 'EXAVITQu4vr4xnSDxMaL';

export async function speakText(text, language = 'en') {
  if (!text || !ELEVENLABS_KEY) return;

  const button = document.getElementById('tts-btn');
  if (button) {
    button.textContent = 'Playing...';
    button.disabled = true;
  }

  try {
    const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`, {
      method: 'POST',
      headers: {
        'xi-api-key': ELEVENLABS_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        text,
        model_id: 'eleven_multilingual_v2',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.8
        }
      })
    });

    if (!response.ok) {
      throw new Error(`ElevenLabs HTTP ${response.status}`);
    }

    const blob = await response.blob();
    const audioUrl = URL.createObjectURL(blob);
    const audio = new Audio(audioUrl);

    audio.onended = () => {
      URL.revokeObjectURL(audioUrl);
      if (button) {
        button.textContent = 'Read aloud';
        button.disabled = false;
      }
    };

    await audio.play();
  } catch (error) {
    console.error('TTS error:', error);
    if (button) {
      button.textContent = 'Read aloud';
      button.disabled = false;
    }
  }
}

export function initTTSButton(getText, getLanguage) {
  const button = document.getElementById('tts-btn');
  if (!button) return;

  button.onclick = async () => {
    const text = typeof getText === 'function' ? getText() : '';
    const language = typeof getLanguage === 'function' ? getLanguage() : 'en';
    await speakText(text, language);
  };
}
