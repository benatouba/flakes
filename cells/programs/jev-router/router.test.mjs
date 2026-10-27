import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { models, redact, route } from './router.mjs';

const fixture = async (t, key = 'synthetic-test-key') => {
  const dir = await mkdtemp(join(tmpdir(), 'jev-router-test-'));
  t.after(() => rm(dir, { recursive: true }));
  const keyFile = join(dir, 'key');
  await writeFile(keyFile, key, { mode: 0o600 });
  return keyFile;
};
const reply = (choice, confidence = 0.9) => new Response(JSON.stringify({ answers: { result: { choice, confidence } } }));

test('redacts common secrets, code blocks, URLs and emails before truncating', () => {
  const sensitive = [
    'sk-test123456789', 'jv_live_synthetic', 'ghp_synthetic',
    'AKIAABCDEFGHIJKLMNOP', 'eyJhbGci.aGVsbG8.c2ln',
    'Authorization: Bearer abc123', 'Bearer abc123',
    'PASSWORD="abc123"', '"api_key":"abc123"', "token='abc123'",
    'https://user:abc123@example.invalid/private?token=abc123',
    'someone@example.invalid', '```private file content```',
    '-----BEGIN PRIVATE KEY-----\nabc123\n-----END PRIVATE KEY-----',
  ];
  for (const value of sensitive) {
    const output = redact(`Please debug ${value}`);
    for (const marker of ['abc123', 'synthetic', 'someone@', 'private file content', 'ABCDEFGHIJKLMNOP']) {
      assert.ok(!output.includes(marker), `${marker} was not redacted`);
    }
  }
  assert.equal(redact('x'.repeat(10000)).length, 4000);
});

test('classifies only redacted prompt with bounded request and fixed endpoint', async t => {
  const keyFile = await fixture(t);
  const result = await route({ client: 'opencode', prompt: 'Fix API_KEY=synthetic-sensitive-value' }, {
    keyFile,
    fetchImpl: async (url, init) => {
      assert.equal(url, 'https://api.typesafe.ai/v1/systemone');
      assert.equal(init.redirect, 'error');
      assert.ok(init.signal instanceof AbortSignal);
      const body = JSON.parse(init.body);
      assert.equal(body.model, 'jev-latest');
      assert.ok(!body.state.includes('synthetic-sensitive-value'));
      assert.deepEqual(Object.keys(body).sort(), ['model', 'questions', 'state']);
      return reply('strong');
    },
  });
  assert.deepEqual(result, { model: models.opencode.strong, source: 'jev', confidence: 0.9 });
});

test('even gateway-shaped keys cannot select an unofficial endpoint', async t => {
  const keyFile = await fixture(t, 'jv_live_synthetic');
  await route({ client: 'claude', prompt: 'Explain a loop' }, {
    keyFile,
    fetchImpl: async url => {
      assert.equal(url, 'https://api.typesafe.ai/v1/systemone');
      return reply('fast');
    },
  });
});

test('all choices stay in explicit latest-generation allowlists', async t => {
  const keyFile = await fixture(t);
  for (const client of Object.keys(models)) {
    for (const choice of ['fast', 'balanced', 'strong']) {
      const actual = await route({ client, prompt: 'Synthetic coding task' }, {
        keyFile, fetchImpl: async () => reply(choice),
      });
      assert.deepEqual(actual.model, models[client][choice]);
    }
  }
});

test('invalid, low-confidence, oversized, failed and timed-out answers use balanced fallback', async t => {
  const keyFile = await fixture(t);
  for (const fetchImpl of [
    async () => reply('claude-old'), async () => reply('__proto__'),
    async () => reply('strong', 0.59), async () => reply('strong', 2),
    async () => new Response('invalid'), async () => new Response('x'.repeat(16385)),
    async () => new Response('private upstream error', { status: 401 }),
    async () => { throw new Error('Synthetic timeout'); },
  ]) {
    assert.deepEqual(await route({ client: 'claude', prompt: 'Test' }, { keyFile, fetchImpl }), {
      model: models.claude.balanced, source: 'fallback',
    });
  }
});

test('missing credentials, empty and huge prompts never call network', async t => {
  const fetchImpl = async () => { assert.fail('Unexpected network call'); };
  const keyFile = await fixture(t, '');
  for (const prompt of ['', 'x'.repeat(65537), 'Test']) {
    assert.equal((await route({ client: 'claude', prompt }, { keyFile, fetchImpl })).source, 'fallback');
  }
  assert.equal((await route({ client: 'claude', prompt: 'Test' }, {
    keyFile: join(keyFile, 'missing'), fetchImpl,
  })).source, 'fallback');
});

test('rejects caller-controlled endpoints, model IDs, history and attachments', async () => {
  for (const extra of ['endpoint', 'model', 'history', 'attachments']) {
    await assert.rejects(route({ client: 'claude', prompt: 'Test', [extra]: 'forbidden' }));
  }
  await assert.rejects(route({ client: '__proto__', prompt: 'Test' }));
});

test('Claude registration only clamps main-loop models; the vendored plugin selects', async () => {
  const source = await readFile(new URL('./claude/hooks/register.js', import.meta.url), 'utf8');
  const { register } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const hooks = new Map();
  register((name, hook) => hooks.set(name, hook));
  // Routing moved out: a second turn.start selector would compete with the
  // vendored plugin's decision for the same turn.
  assert.ok(!hooks.has('turn.start'));
  const $ = {};
  const step = async event => {
    const output = [];
    for await (const value of hooks.get('turn.step')($, event, async function* (e) { yield e; })) output.push(value);
    return output[0];
  };
  // A main-loop model outside the approved 5.5 trio fails closed to the safe
  // allowed model instead of following a stale or older-generation choice.
  assert.equal((await step({ model: 'old-model' })).model, models.claude.balanced);
  assert.equal((await step({ turnId: 'one', model: 'claude-fable-5-1' })).model, models.claude.balanced);
  // Approved 5.5 models pass through untouched.
  for (const model of Object.values(models.claude)) {
    assert.equal((await step({ model })).model, model);
  }
  // Subagent requests keep the model their agent configuration chose; agent
  // configuration is explicit local policy, not routing output.
  assert.equal((await step({ agentId: 'agent-1', model: 'configured-model' })).model, 'configured-model');
  // Compaction scheduling stays local and untouched by this change.
  assert.equal(typeof hooks.get('turn.complete'), 'function');
  assert.equal(typeof hooks.get('session.end'), 'function');
});

test('OpenCode prompt hook selects model and request guard rejects other providers/generations', async () => {
  // Exercise the actual plugin hooks with a stub subprocess; no network/auth.
  const source = (await readFile(new URL('./opencode.mjs', import.meta.url), 'utf8'))
    .replace("from './controls.mjs'", `from '${new URL('./controls.mjs', import.meta.url).href}'`)
    .replace("from './cache-policy.mjs'", `from '${new URL('./cache-policy.mjs', import.meta.url).href}'`)
    .replace("import { execFile } from 'node:child_process';", `
      const execFile = (path, args, opts, cb) => {
        queueMicrotask(() => cb(null, JSON.stringify({model: {providerID:'openai', id:'gpt-6.1-terra',variant:'high'}, source:'jev', confidence: 0.9})));
        return {stdin: {on() {}, end() {}}};
      };`);
  const { default: plugin } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const hooks = new Map();
  let selected;
  let disposed = 0;
  const domain = { hook: async (name, hook) => { hooks.set(name, hook); return { dispose: async () => disposed++ }; } };
  const cleanup = await plugin.setup({ skill: { list: async () => ({ data: [] }) }, permission: domain, tool: domain, shell: domain, session: {
    hook: async (name, hook) => { hooks.set(name, hook); return { dispose: async () => disposed++ }; },
    switchModel: async input => { selected = input; },
  } });
  await hooks.get('prompt')({ sessionID: 'test', prompt: { text: 'Synthetic task', files: ['excluded'] } });
  assert.equal(selected.model.id, 'gpt-6.1-terra');
  hooks.get('model.request')({ model: selected.model });
  for (const model of [{ providerID: 'other', id: 'gpt-6.1-sol' }, { providerID: 'openai', id: 'gpt-5' }]) {
    assert.throws(() => hooks.get('model.request')({ model }));
  }
  await cleanup();
  assert.equal(disposed, 11);
});

test('warm cache keeps the current model while downgrading, and changes effort in place', async () => {
  const source = (await readFile(new URL('./opencode.mjs', import.meta.url), 'utf8'))
    .replace("from './controls.mjs'", `from '${new URL('./controls.mjs', import.meta.url).href}'`)
    .replace("from './cache-policy.mjs'", `from '${new URL('./cache-policy.mjs', import.meta.url).href}'`)
    .replace("import { execFile } from 'node:child_process';", `
      const execFile = (path, args, opts, cb) => {
        return {stdin: {on() {}, end(text) {
          const input = JSON.parse(text);
          const output = input.task === 'skills'
            ? { skill: null }
            : { model: {providerID:'openai', id:'gpt-6.1-sol', variant:'low'}, source:'jev', confidence: 0.9 };
          queueMicrotask(() => cb(null, JSON.stringify(output)));
        }}}; };`);
  const { default: plugin } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const hooks = new Map();
  let selected;
  let disposed = 0;
  const domain = { hook: async (name, hook) => { hooks.set(name, hook); return { dispose: async () => disposed++ }; } };
  // A completed terra step with a real cache hit and worth-protecting context.
  const event = {
    subscribe: () => (async function* () {
      yield { type: 'session.step.started', data: { sessionID: 'warm', assistantMessageID: 'msg-1',
        model: { providerID: 'openai', id: 'gpt-6.1-terra', variant: 'high' } } };
      yield { type: 'session.step.ended', data: { sessionID: 'warm', assistantMessageID: 'msg-1',
        tokens: { input: 100, output: 50, reasoning: 0, cache: { read: 9000, write: 100 } } } };
    })(),
  };
  const cleanup = await plugin.setup({
    skill: { list: async () => ({ data: [] }) },
    permission: domain, tool: domain, shell: domain, event,
    session: {
      hook: async (name, hook) => { hooks.set(name, hook); return { dispose: async () => disposed++ }; },
      switchModel: async input => { selected = input; },
    },
  });
  // Let the event pump consume the synthetic step telemetry.
  await new Promise(resolve => setImmediate(resolve));
  await hooks.get('prompt')({ sessionID: 'warm', prompt: { text: 'Simple tweak', skills: [] } });
  // Classifier prefers sol/low, but the warm terra cache survives the downgrade:
  // only the effort changes, in place.
  assert.equal(selected.model.id, 'gpt-6.1-terra');
  assert.equal(selected.model.variant, 'low');
  await cleanup();
  assert.equal(disposed, 11);
});

test('classifier failure keeps the current allowed model without a switch', async () => {
  const source = (await readFile(new URL('./opencode.mjs', import.meta.url), 'utf8'))
    .replace("from './controls.mjs'", `from '${new URL('./controls.mjs', import.meta.url).href}'`)
    .replace("from './cache-policy.mjs'", `from '${new URL('./cache-policy.mjs', import.meta.url).href}'`)
    .replace("import { execFile } from 'node:child_process';", `
      const execFile = (path, args, opts, cb) => {
        queueMicrotask(() => cb(new Error('synthetic outage')));
        return {stdin: {on() {}, end() {}}};
      };`);
  const { default: plugin } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const hooks = new Map();
  let switched = false;
  let disposed = 0;
  const domain = { hook: async (name, hook) => { hooks.set(name, hook); return { dispose: async () => disposed++ }; } };
  const cleanup = await plugin.setup({
    skill: { list: async () => ({ data: [] }) },
    permission: domain, tool: domain, shell: domain,
    session: {
      hook: async (name, hook) => { hooks.set(name, hook); return { dispose: async () => disposed++ }; },
      switchModel: async () => { switched = true; },
    },
  });
  await hooks.get('prompt')({ sessionID: 'outage', prompt: { text: 'Anything', skills: [] } });
  assert.equal(switched, false, 'a failed classification must not move the session');
  await cleanup();
  assert.equal(disposed, 11);
});
