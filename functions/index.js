/**
 * Cardly Cloud Functions — Groq proxy (OpenAI-compatible, free tier).
 *
 * The API key lives ONLY here (as a Functions secret), never in the app.
 * Both callables require an authenticated Firebase user.
 *
 * Setup:   firebase functions:secrets:set GROQ_API_KEY   (key from console.groq.com)
 * Deploy:  firebase deploy --only functions
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const GROQ_API_KEY = defineSecret("GROQ_API_KEY");
const REGION = "asia-northeast3";                 // Seoul — matches Firestore
const MODEL = "llama-3.3-70b-versatile";          // Groq free tier, strong JSON
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

/** Minimal Groq chat call (OpenAI-compatible). Returns the message content. */
async function groqChat(apiKey, system, user, { json = false } = {}) {
  const res = await fetch(GROQ_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      temperature: 0.4,
      messages: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
      ...(json ? { response_format: { type: "json_object" } } : {}),
    }),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    console.error("Groq error:", res.status, detail);
    throw new HttpsError("internal", "AI 호출에 실패했어요. 잠시 후 다시 시도해주세요.");
  }
  const data = await res.json();
  return data?.choices?.[0]?.message?.content ?? "";
}

/** content + count → [{front, back, hint?}] */
exports.generateCards = onCall(
  { secrets: [GROQ_API_KEY], region: REGION },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");

    const content = String(req.data?.content ?? "").slice(0, 20000).trim();
    const count = Math.min(Math.max(parseInt(req.data?.count, 10) || 10, 1), 30);
    if (!content) throw new HttpsError("invalid-argument", "학습 자료가 비어 있습니다.");

    const system = "너는 학습 보조 도구야. 주어진 자료로 플래시카드를 만들고 반드시 JSON만 출력해.";
    const user =
      `다음 자료에서 핵심 개념을 추출해 플래시카드 ${count}개를 만들어줘.\n` +
      `규칙: 카드 하나당 개념 하나, front는 질문, back은 간결한 정답, hint는 선택. 모두 한국어.\n` +
      `출력은 이 JSON 형식만: {"cards":[{"front":"...","back":"...","hint":"..."}]}\n\n` +
      `자료:\n${content}`;

    const raw = await groqChat(GROQ_API_KEY.value(), system, user, { json: true });
    try {
      const parsed = JSON.parse(raw);
      const cards = Array.isArray(parsed) ? parsed : parsed?.cards ?? [];
      return { cards: Array.isArray(cards) ? cards.slice(0, count) : [] };
    } catch (e) {
      console.error("generateCards parse failed:", raw);
      throw new HttpsError("internal", "카드 생성 결과를 해석하지 못했어요. 다시 시도해주세요.");
    }
  }
);

/** front + back → short explanation string */
exports.explainCard = onCall(
  { secrets: [GROQ_API_KEY], region: REGION },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");

    const front = String(req.data?.front ?? "").slice(0, 2000);
    const back = String(req.data?.back ?? "").slice(0, 2000);

    const system = "너는 친절한 학습 튜터야. 한국어로 간결하고 명확하게 설명해.";
    const user =
      `플래시카드 질문: ${front}\n정답: ${back}\n\n` +
      `왜 이 정답이 맞는지 2~3문장으로 친절하게 설명하고, 관련 개념을 짧게 보충해줘.`;

    const explanation = await groqChat(GROQ_API_KEY.value(), system, user);
    return { explanation };
  }
);
