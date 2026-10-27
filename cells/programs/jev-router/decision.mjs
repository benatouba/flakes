import { readFile } from 'node:fs/promises';

// One issuer and one destination, regardless of key shape or environment.
export async function choose(state, criteria, instructions, { keyFile, fetchImpl = fetch } = {}) {
  try {
    const key = (await readFile(keyFile, 'utf8')).trim();
    if (!key || key.length > 4096 || /\s/.test(key)) return null;
    const response = await fetchImpl('https://api.typesafe.ai/v1/systemone', {
      method: 'POST', redirect: 'error', signal: AbortSignal.timeout(4000),
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'jev-latest', state,
        questions: { result: { type: 'choice', instructions, criteria } } }),
    });
    if (!response.ok) { await response.body?.cancel(); return null; }
    const reader = response.body.getReader();
    const chunks = [];
    let size = 0;
    try {
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        size += value.length;
        if (size > 16384) return null;
        chunks.push(value);
      }
    } finally { await reader.cancel(); }
    const answer = JSON.parse(Buffer.concat(chunks).toString('utf8'))?.answers?.result;
    if (!answer || !Object.hasOwn(criteria, answer.choice)
      || !Number.isFinite(answer.confidence) || answer.confidence < 0.6 || answer.confidence > 1) return null;
    // Confidence is returned so warm-cache upgrades can require a firm answer.
    return { choice: answer.choice, confidence: answer.confidence };
  } catch { return null; }
}
