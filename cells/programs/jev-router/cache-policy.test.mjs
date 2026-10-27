import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  cachePlan, isWarm, WARM_TTL_MS, MIN_CONTEXT_TOKENS, MIN_UPGRADE_CONFIDENCE,
} from './cache-policy.mjs';

const sol = { providerID: 'openai', id: 'gpt-6.1-sol', variant: 'medium', confidence: 0.9 };
const terra = { providerID: 'openai', id: 'gpt-6.1-terra', variant: 'high', confidence: 0.9 };
const NOW = 1_000_000;
const warm = (model, overrides = {}) => ({
  model, at: NOW, contextTokens: 20_000, cacheRead: 5_000, ...overrides,
});

test('classifier failure or an unknown model keeps the current model', () => {
  assert.equal(cachePlan(null, warm('gpt-6.1-terra'), NOW), null);
  assert.equal(cachePlan(undefined, undefined, NOW), null);
  assert.equal(cachePlan({ ...sol, id: 'gpt-5' }, warm('gpt-6.1-terra'), NOW), null);
});

test('without fresh cache evidence the classifier decides', () => {
  assert.deepEqual(cachePlan(sol, undefined, NOW), { model: 'gpt-6.1-sol', variant: 'medium' });
  // Expired warmth.
  assert.deepEqual(
    cachePlan(sol, warm('gpt-6.1-terra', { at: NOW - WARM_TTL_MS - 1 }), NOW),
    { model: 'gpt-6.1-sol', variant: 'medium' },
  );
  // Context too small to be worth protecting.
  assert.deepEqual(
    cachePlan(sol, warm('gpt-6.1-terra', { contextTokens: MIN_CONTEXT_TOKENS - 1 }), NOW),
    { model: 'gpt-6.1-sol', variant: 'medium' },
  );
  // No observed cache hit is not warmth.
  assert.deepEqual(
    cachePlan(sol, warm('gpt-6.1-terra', { cacheRead: 0 }), NOW),
    { model: 'gpt-6.1-sol', variant: 'medium' },
  );
  // Unrecognized state models are never trusted as warmth.
  assert.deepEqual(
    cachePlan(sol, warm('claude-opus-5-5'), NOW),
    { model: 'gpt-6.1-sol', variant: 'medium' },
  );
});

test('warm cache keeps the model and changes effort first', () => {
  // Downgrade while warm: keep the cached model, apply the cheaper effort.
  assert.deepEqual(cachePlan(sol, warm('gpt-6.1-terra'), NOW), { model: 'gpt-6.1-terra', variant: 'medium' });
  // Low-confidence upgrade while warm: effort first, no cache reset.
  const shyTerra = { ...terra, confidence: MIN_UPGRADE_CONFIDENCE - 0.01 };
  assert.deepEqual(cachePlan(shyTerra, warm('gpt-6.1-sol'), NOW), { model: 'gpt-6.1-sol', variant: 'high' });
  // A confident upgrade pays the cache reset.
  assert.deepEqual(cachePlan(terra, warm('gpt-6.1-sol'), NOW), { model: 'gpt-6.1-terra', variant: 'high' });
  // Same model: only the effort changes, in place.
  assert.deepEqual(cachePlan(sol, warm('gpt-6.1-sol'), NOW), { model: 'gpt-6.1-sol', variant: 'medium' });
});

test('warmth boundaries are inclusive of the TTL and exclusive of zero evidence', () => {
  assert.equal(isWarm(warm('gpt-6.1-sol', { at: NOW - WARM_TTL_MS }), NOW), true);
  assert.equal(isWarm(warm('gpt-6.1-sol', { at: NOW - WARM_TTL_MS - 1 }), NOW), false);
  // A slightly-ahead timestamp (clock skew) is fresher, not colder.
  assert.equal(isWarm(warm('gpt-6.1-sol', { at: NOW + 1 }), NOW), true);
  assert.equal(isWarm(null, NOW), false);
});
