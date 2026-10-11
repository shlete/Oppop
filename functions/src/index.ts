// 타로 고민상담 통합 점괘를 Claude로 써 주는 함수.
// 앱은 주제와 카드 id만 보내고, 카드 뜻과 프롬프트는 서버가 직접 만든다.
// 그래서 앱에서 보낸 글이 프롬프트에 섞이지 않는다.
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { onRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import cards from "./cards.json";

const anthropicKey = defineSecret("ANTHROPIC_API_KEY");

type Reading = {
  keywords: string[];
  love: string;
  study: string;
  career: string;
  money: string;
  health: string;
};
type Card = { id: string; name: string; nameEn: string; upright: Reading; reversed: Reading };

const deck = new Map((cards as Card[]).map((c) => [c.id, c]));

const topics = {
  love: "연애",
  study: "학업",
  career: "진로",
  money: "금전",
  health: "건강",
} as const;
type Topic = keyof typeof topics;

const positions = ["과거 · 원인", "현재 · 상황", "미래 · 조언"];

const RequestSchema = z.object({
  topic: z.enum(["love", "study", "career", "money", "health"]),
  cards: z
    .array(z.object({ id: z.string(), reversed: z.boolean() }))
    .length(3),
});

// 자리별 글을 배열 대신 칸 3개로 받아야 늘 3개가 온다.
const ReadingSchema = z.object({
  flow: z.string(),
  past: z.string(),
  present: z.string(),
  future: z.string(),
  advice: z.string(),
});

const system = `너는 '오늘의 뽑기' 앱의 타로 상담가야. 출퇴근길에 가볍게 보는 앱이라 따뜻하고 다정한 존댓말(~해요)로 쓴다.
규칙:
- 카드 뜻은 함께 주는 설명을 바탕으로 하되, 세 장이 하나의 이야기로 이어지게 풀어 쓴다.
- flow: 세 장의 흐름을 한 문장으로 (40자 안팎).
- past, present, future: 과거·현재·미래 자리 해석, 각 2~3문장 (90~140자).
- advice: 오늘 해 볼 만한 작은 행동 하나를 담은 한 문장.
- 겁주거나 단정하지 않는다. 죽음, 질병 진단, 투자 종목, 법률 판단 같은 말은 하지 않는다.
- 건강 주제는 생활 습관 수준으로만 말하고, 걱정되면 전문가와 상담하라고 부드럽게 권한다.
- 카드 영어 이름이나 '정방향/역방향'이라는 단어는 쓰지 않는다. 이모지도 쓰지 않는다.`;

function prompt(topic: Topic, drawn: { card: Card; reversed: boolean }[]) {
  const lines = drawn.map(({ card, reversed }, i) => {
    const r = reversed ? card.reversed : card.upright;
    return `${positions[i]}: ${card.name}${reversed ? " (역방향)" : ""}
  키워드: ${r.keywords.join(", ")}
  ${topics[topic]} 해석 참고: ${r[topic]}`;
  });
  return `고민 주제: ${topics[topic]}\n\n${lines.join("\n\n")}`;
}

export const tarotReading = onRequest(
  {
    region: "asia-northeast3",
    secrets: [anthropicKey],
    cors: true,
    maxInstances: 10,
    timeoutSeconds: 30,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).end();
      return;
    }
    const body = RequestSchema.safeParse(req.body);
    if (!body.success) {
      res.status(400).json({ error: "bad_request" });
      return;
    }
    const drawn = body.data.cards.map((c) => ({ card: deck.get(c.id), reversed: c.reversed }));
    if (drawn.some((d) => !d.card) || new Set(body.data.cards.map((c) => c.id)).size !== 3) {
      res.status(400).json({ error: "bad_cards" });
      return;
    }

    const client = new Anthropic({ apiKey: anthropicKey.value() });
    try {
      const response = await client.messages.parse({
        model: "claude-haiku-5-5",
        max_tokens: 3000,
        thinking: { type: "disabled" },
        system,
        messages: [
          {
            role: "user",
            content: prompt(body.data.topic, drawn as { card: Card; reversed: boolean }[]),
          },
        ],
        output_config: { effort: "low", format: zodOutputFormat(ReadingSchema) },
      });
      const out = response.parsed_output;
      if (response.stop_reason === "refusal" || !out) {
        // 앱은 이 경우 미리 써 둔 점괘를 보여준다.
        const text = response.content
          .map((b) => (b.type === "text" ? b.text : `[${b.type}]`))
          .join("")
          .slice(0, 500);
        logger.warn("no reading", {
          stop: response.stop_reason,
          usage: response.usage,
          text,
        });
        res.status(502).json({ error: "no_reading" });
        return;
      }
      res.json({
        flow: out.flow,
        positions: [out.past, out.present, out.future],
        advice: out.advice,
      });
    } catch (e) {
      logger.error("claude failed", e);
      res.status(502).json({ error: "upstream" });
    }
  },
);
