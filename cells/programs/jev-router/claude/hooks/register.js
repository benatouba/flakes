const allowed = ['claude-haiku-5-5', 'claude-sonnet-5-5', 'claude-opus-5-5'];
const fallback = 'claude-sonnet-5-5';

// Model selection lives in the vendored jev-router plugin; this module keeps
// only local safety controls so exactly one selector owns each turn.
export function register(on) {
  let lastCheckpoint = 0;

  // Final allowlist clamp: a main-loop request outside the approved 5.5 trio
  // falls back to the safe allowed model (fail closed). Subagent requests keep
  // the model their agent configuration chose: explicit local configuration,
  // not routing output. Guards never widen permissions.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId === undefined && !allowed.includes(e.model)) {
      yield* next({ ...e, model: fallback });
      return;
    }
    yield* next(e);
  });

  on('turn.complete', async ($, e, next) => {
    const completed = await next(e);
    if (e.agentId || e.reason !== 'answer') return completed;
    // Scheduling only: never read or rewrite the transcript. Keep native overflow
    // handling, including when the classifier/mod is unavailable.
    try {
      const now = Date.now();
      const { context } = await $.session.usage();
      if (context.percent >= 80 && now - lastCheckpoint >= 300000) {
        lastCheckpoint = now;
        const result = await $.process.run(['@control@'], {
          stdin: JSON.stringify({ task: 'compact', percent: context.percent }), timeoutMs: 6000,
        });
        if (result.exitCode === 0 && JSON.parse(result.stdout).compact === true) {
          await $.session.compact({ instructions: 'Preserve goals, explicit constraints, unresolved issues and recent work. Keep native tool-call/result continuity.' });
        }
      }
    } catch { /* Native auto-compaction remains available; no input logging. */ }
    return completed;
  });

  on('session.end', async ($, e, next) => {
    lastCheckpoint = 0;
    return next(e);
  });
}
