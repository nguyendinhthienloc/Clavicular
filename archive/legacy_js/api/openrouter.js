const OPENROUTER_KEY = window.ENV?.OPENROUTER_KEY || '';

const SYSTEM_EN = `You are a medical triage AI. Analyze the patient's body region and symptoms.
Respond ONLY with raw valid JSON. No markdown, no backticks, no explanation.

{
  "conditions": [
    { "name": "string", "likelihood": "High|Medium|Low", "explanation": "max 20 words" }
  ],
  "severity": "Low|Medium|High|Emergency",
  "action": "One clear sentence on what the patient should do.",
  "home_tips": ["tip 1", "tip 2"],
  "warning_signs": ["sign 1"],
  "disclaimer": "This is AI information only, not medical advice. For emergencies call 115."
}

Rules:
- 2 to 3 conditions, most likely first
- "Emergency" only for life-threatening signs (chest pain radiating to arm, appendicitis, stroke)
- Keep explanations under 20 words
- Always include the disclaimer field exactly as shown`;

const SYSTEM_VI = `Bạn là AI phân loại y tế. Phân tích vùng cơ thể và triệu chứng.
Chỉ trả lời bằng JSON thuần túy, không markdown, không backtick.

{
  "conditions": [
    { "name": "string", "likelihood": "High|Medium|Low", "explanation": "tối đa 20 từ" }
  ],
  "severity": "Low|Medium|High|Emergency",
  "action": "Một câu rõ ràng về việc cần làm.",
  "home_tips": ["mẹo 1", "mẹo 2"],
  "warning_signs": ["dấu hiệu 1"],
  "disclaimer": "Đây chỉ là thông tin AI, không phải lời khuyên y tế. Cấp cứu gọi 115."
}

Bạn MUST trả lời hoàn toàn bằng Tiếng Việt.`;

function fallbackDiagnosis(language) {
  if (language === 'vi') {
    return {
      conditions: [
        {
          name: 'Không thể phân tích',
          likelihood: 'Low',
          explanation: 'Vui lòng thử lại hoặc tham khảo bác sĩ trực tiếp.'
        }
      ],
      severity: 'Medium',
      action: 'Vui lòng tham khảo bác sĩ hoặc cơ sở y tế gần nhất.',
      home_tips: ['Nghỉ ngơi và theo dõi triệu chứng', 'Ghi lại thời gian và mức độ đau'],
      warning_signs: ['Đau tăng đột ngột', 'Khó thở', 'Mất ý thức'],
      disclaimer: 'Đây chỉ là thông tin AI, không phải lời khuyên y tế. Cấp cứu gọi 115.'
    };
  }

  return {
    conditions: [
      {
        name: 'Analysis unavailable',
        likelihood: 'Low',
        explanation: 'Please try again or consult a doctor directly.'
      }
    ],
    severity: 'Medium',
    action: 'Please consult a doctor or visit your nearest clinic.',
    home_tips: ['Rest and monitor your symptoms'],
    warning_signs: ['Sudden worsening', 'Difficulty breathing'],
    disclaimer: 'This is AI information only, not medical advice. For emergencies call 115.'
  };
}

function parseModelContent(rawText) {
  if (!rawText || typeof rawText !== 'string') {
    throw new Error('Model returned empty content');
  }

  const cleaned = rawText
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/```\s*$/i, '')
    .trim();

  const parsed = JSON.parse(cleaned);
  if (!parsed.conditions || !parsed.severity || !parsed.action) {
    throw new Error('Bad JSON shape');
  }

  return parsed;
}

async function requestDiagnosis(model, systemPrompt, userMessage) {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${OPENROUTER_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': window.location.origin,
      'X-Title': 'BodyCheck — LotusHacks 2026'
    },
    body: JSON.stringify({
      model,
      max_tokens: 900,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage }
      ]
    })
  });

  if (!response.ok) {
    throw new Error(`OpenRouter HTTP ${response.status}`);
  }

  const data = await response.json();
  return parseModelContent(data?.choices?.[0]?.message?.content || '');
}

export async function callDiagnosis(userMessage, language = 'en') {
  const selectedLanguage = language === 'vi' ? 'vi' : 'en';
  const primaryModel = selectedLanguage === 'vi'
    ? 'qwen/qwen-2.5-72b-instruct'
    : 'anthropic/claude-3.5-sonnet';
  const fallbackModel = 'openai/gpt-4o-mini';
  const systemPrompt = selectedLanguage === 'vi' ? SYSTEM_VI : SYSTEM_EN;

  if (!OPENROUTER_KEY) {
    console.warn('OPENROUTER_KEY missing in window.ENV');
    return fallbackDiagnosis(selectedLanguage);
  }

  try {
    return await requestDiagnosis(primaryModel, systemPrompt, userMessage);
  } catch (error) {
    console.error('Primary OpenRouter call failed:', error);
    try {
      return await requestDiagnosis(fallbackModel, systemPrompt, userMessage);
    } catch (fallbackError) {
      console.error('Fallback OpenRouter call failed:', fallbackError);
      return fallbackDiagnosis(selectedLanguage);
    }
  }
}
