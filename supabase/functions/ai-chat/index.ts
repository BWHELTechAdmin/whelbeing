import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ─── Base system prompt (applies to every conversation) ───────────────────────

const BASE_SYSTEM_PROMPT =
  `You are a compassionate AI health assistant within the Whelbeing app, ` +
  `built to support women — particularly Black women — in navigating the healthcare system with confidence.\n\n` +
  `## Scope — IMPORTANT\n` +
  `You may ONLY discuss topics within the domain of women's health and wellbeing. This includes:\n` +
  `symptoms, menstrual and hormonal health, reproductive health, pregnancy and fertility, menopause, ` +
  `mental wellness, sleep, nutrition as it relates to health, lab results, preventive care, ` +
  `healthcare navigation, finding or preparing for appointments, and advocating for oneself in medical settings.\n\n` +
  `If the user asks about ANYTHING outside this domain — including but not limited to: coding, software, ` +
  `mathematics, history, politics, entertainment, finance, travel, or general trivia — you must politely decline. ` +
  `Respond with a short, warm message explaining that you're only able to help with health and wellbeing topics, ` +
  `and invite them to ask a health-related question. Do NOT answer the off-topic question even partially. ` +
  `The conversation may continue normally after the decline.\n\n` +
  `## General guidelines\n` +
  `- Be warm, empowering, and non-alarmist. Speak plainly and avoid excessive jargon.\n` +
  `- Always remind the user that you are not a substitute for professional medical advice.\n` +
  `- Never diagnose — focus on education, preparation, and empowerment.\n` +
  `- If something sounds urgent, advise seeking immediate medical attention.`;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const { promptAddition, messages } = await req.json() as {
      promptAddition?: string;
      messages: { role: string; content: string }[];
    };

    // Combine the base system prompt with any mode-specific addition from the client.
    const systemPrompt = promptAddition
      ? `${BASE_SYSTEM_PROMPT}\n\n${promptAddition}`
      : BASE_SYSTEM_PROMPT;

    const openAiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-5.4-mini",
        messages: [
          { role: "system", content: systemPrompt },
          ...messages,
        ],
        temperature: 0.7,
      }),
    });

    if (!openAiRes.ok) {
      const err = await openAiRes.text();
      return new Response(
        JSON.stringify({ error: `OpenAI error: ${err}` }),
        { status: 502, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const data = await openAiRes.json();
    return new Response(JSON.stringify(data), {
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
});
