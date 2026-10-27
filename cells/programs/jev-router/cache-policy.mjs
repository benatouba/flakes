// Warm-cache stickiness for OpenCode model selection. A completed step leaves
// observable cache evidence; while that cache is warm, only a confident upgrade
// may pay the cost of moving the conversation to another model. Variant (effort)
// changes stay available in place because they preserve the prompt prefix on
// GPT-6.1, so a cheap task keeps the cached model and only adjusts effort.

export const WARM_TTL_MS = 300_000;
export const MIN_CONTEXT_TOKENS = 8_000;
export const MIN_UPGRADE_CONFIDENCE = 0.7;

const STRENGTH = Object.freeze({ 'gpt-6.1-sol': 0, 'gpt-6.1-terra': 1 });

// Warmth requires fresh completion evidence, a context worth protecting and an
// actual cache hit. Missing or partial telemetry is treated as cold: routing
// then simply follows the classifier, never assuming an unobserved cache.
export function isWarm(state, now = Date.now()) {
  return Boolean(state
    && Object.hasOwn(STRENGTH, state.model)
    && Number.isFinite(state.at) && now - state.at <= WARM_TTL_MS
    && state.contextTokens >= MIN_CONTEXT_TOKENS
    && state.cacheRead > 0);
}

// Returns the switch to apply, or null when the classifier failed and the
// current allowed model must be kept. Downgrades and low-confidence upgrades
// while warm become in-place effort changes instead of model switches.
export function cachePlan(target, state, now = Date.now()) {
  if (!target || !Object.hasOwn(STRENGTH, target.id)) return null;
  if (!isWarm(state, now) || target.id === state.model) {
    return { model: target.id, variant: target.variant };
  }
  if (STRENGTH[target.id] > STRENGTH[state.model] && target.confidence >= MIN_UPGRADE_CONFIDENCE) {
    return { model: target.id, variant: target.variant };
  }
  return { model: state.model, variant: target.variant };
}
