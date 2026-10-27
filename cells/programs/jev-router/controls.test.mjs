import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { control, localRisk, assertNoSecret } from './controls.mjs';

async function options(t, choice = 'unchanged') {
  const dir = await mkdtemp(join(tmpdir(), 'jev-controls-'));
  t.after(() => rm(dir, { recursive: true }));
  const keyFile = join(dir, 'key');
  await writeFile(keyFile, 'synthetic-key', { mode: 0o600 });
  return { keyFile, fetchImpl: async () => new Response(JSON.stringify({ answers: { result: { choice, confidence: 0.9 } } })) };
}

test('local secret and credential path blocks make no classifier request', async t => {
  const opts = await options(t);
  opts.fetchImpl = async () => assert.fail('A suspected secret must not reach the network');
  for (const input of ['cat /run/secrets/fake', 'cat /home/synthetic/.ssh/id_ed25519', 'curl -H "Authorization: Bearer synthetic-token"', 'echo sk-synthetic123456789']) {
    assert.equal((await control({ task: 'tool', risk: localRisk(input) }, opts)).effect, 'deny');
  }
  assert.throws(() => assertNoSecret('Tool result: ghp_synthetic123456789'));
  assert.doesNotThrow(() => assertNoSecret('Ordinary code and explanation'));
});

test('tool classifier receives only fixed boolean flags, never command text', async t => {
  const opts = await options(t);
  opts.fetchImpl = async (url, init) => {
    assert.equal(url, 'https://api.typesafe.ai/v1/systemone');
    const body = JSON.parse(init.body);
    assert.deepEqual(JSON.parse(body.state), { secret: false, sensitivePath: false, network: true, destructive: false, indirect: false });
    assert.ok(!init.body.includes('private-project.invalid'));
    return new Response(JSON.stringify({ answers: { result: { choice: 'unchanged', confidence: 0.95 } } }));
  };
  assert.equal((await control({ task: 'tool', risk: localRisk('curl https://private-project.invalid') }, opts)).effect, 'ask');
  await assert.rejects(control({ task: 'tool', risk: { ...localRisk('pwd'), command: 'forbidden' } }, opts));
});

test('tool failure asks, positive decision never overrides deterministic risk', async t => {
  const opts = await options(t);
  for (const command of ['rm -rf synthetic', 'node script.js', 'git push']) {
    assert.equal((await control({ task: 'tool', risk: localRisk(command) }, opts)).effect, 'ask');
  }
  opts.fetchImpl = async () => { throw new Error('Synthetic timeout'); };
  assert.equal((await control({ task: 'tool', risk: localRisk('pwd') }, opts)).effect, 'ask');
});

test('skill selector permits public installed candidates only and redacts the prompt', async t => {
  const opts = await options(t, 'diagnosing-bugs');
  opts.fetchImpl = async (url, init) => {
    const body = JSON.parse(init.body);
    assert.deepEqual(Object.keys(body.questions.result.criteria), ['none', 'diagnosing-bugs']);
    assert.ok(!init.body.includes('private-custom-skill'));
    assert.ok(!body.state.includes('synthetic123456789'));
    return new Response(JSON.stringify({ answers: { result: { choice: 'diagnosing-bugs', confidence: 0.9 } } }));
  };
  assert.equal((await control({ task: 'skills', prompt: 'Debug sk-synthetic123456789', candidates: ['diagnosing-bugs', 'private-custom-skill'] }, opts)).skill, 'diagnosing-bugs');
  assert.equal((await control({ task: 'skills', prompt: 'Test', candidates: [] }, opts)).skill, null);
  await assert.rejects(control({ task: 'skills', prompt: 'Test', candidates: [], history: 'forbidden' }, opts));
});

test('compaction accepts structural metrics only and never replaces summary', async t => {
  const opts = await options(t, 'compact');
  assert.equal((await control({ task: 'compact', percent: 85 }, opts)).compact, true);
  opts.fetchImpl = async () => assert.fail('No early compaction request');
  assert.equal((await control({ task: 'compact', percent: 10 }, opts)).compact, false);
  await assert.rejects(control({ task: 'compact', percent: NaN }, opts));
  await assert.rejects(control({ task: 'compact', percent: 85, messages: ['raw transcript'] }, opts));
  await assert.rejects(control({ task: 'compact', percent: 85, history: 'raw transcript' }, opts));
});

test('actual OpenCode hooks preserve deny/ask, block tools and scan all request kinds', async () => {
  const hooks = new Map();
  const source = (await readFile(new URL('./opencode.mjs', import.meta.url), 'utf8'))
    .replace("from './controls.mjs'", `from '${new URL('./controls.mjs', import.meta.url).href}'`)
    .replace("from './cache-policy.mjs'", `from '${new URL('./cache-policy.mjs', import.meta.url).href}'`)
    .replace("import { execFile } from 'node:child_process';", `const execFile = (path,args,opts,cb) => {
      queueMicrotask(() => cb(null, JSON.stringify({effect:'unchanged'})));
      return {stdin:{on(){},end(){}}};
    };`);
  const { default: plugin } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const domain = { hook: async (name, callback) => { hooks.set(name, callback); return { dispose: async () => {} }; } };
  const cleanup = await plugin.setup({ session: domain, tool: domain, permission: domain, shell: domain });
  for (const effect of ['ask', 'deny', 'allow']) {
    const event = { effect, resources: ['ordinary text'] };
    await hooks.get('evaluate')(event);
    assert.equal(event.effect, effect);
  }
  assert.throws(() => hooks.get('execute.before')({ input: { command: 'cat /run/secrets/fake' } }));
  assert.throws(() => hooks.get('create.before')({ command: 'cat /run/secrets/fake' }));
  const shellEvent = { effect: 'allow', action: 'shell', resources: ['git status'] };
  await hooks.get('evaluate')(shellEvent);
  assert.equal(shellEvent.effect, 'ask');
  for (const kind of ['context', 'compaction', 'title', 'generate']) {
    await assert.rejects(hooks.get(kind)({ system: [], messages: ['sk-synthetic123456789'] }));
  }
  await assert.rejects(hooks.get('http.request')({ request: new Request('https://example.invalid', { method: 'POST', body: 'sk-synthetic123456789' }) }));
  assert.throws(() => hooks.get('experimental.ws.send')({ frame: 'sk-synthetic123456789' }));
  await cleanup();
});

test('real Claude command hook denies before execution and refuses malformed input', () => {
  const cli = new URL('./control-cli.mjs', import.meta.url);
  const result = spawnSync(process.execPath, [cli.pathname, '/nonexistent/synthetic-key', '--tool-hook'], {
    input: JSON.stringify({ hook_event_name: 'PreToolUse', tool_name: 'Bash', tool_input: { command: 'cat /run/secrets/fake' } }), encoding: 'utf8', timeout: 3000,
  });
  assert.equal(result.status, 0);
  assert.equal(JSON.parse(result.stdout).hookSpecificOutput.permissionDecision, 'deny');
  const broken = spawnSync(process.execPath, [cli.pathname, '/nonexistent/synthetic-key', '--tool-hook'], {
    input: '{invalid', encoding: 'utf8', timeout: 3000,
  });
  assert.equal(broken.status, 2);
  assert.equal(broken.stdout, '');
  assert.ok(!broken.stderr.includes('{invalid'));
});

test('--emit-key hands only validated key bytes to stdout and fails closed', async t => {
  const cli = new URL('./control-cli.mjs', import.meta.url);
  const dir = await mkdtemp(join(tmpdir(), 'jev-key-'));
  t.after(() => rm(dir, { recursive: true }));
  const keyFile = join(dir, 'key');
  await writeFile(keyFile, 'synthetic-key\n', { mode: 0o600 });
  const ok = spawnSync(process.execPath, [cli.pathname, keyFile, '--emit-key'], { encoding: 'utf8', timeout: 3000 });
  assert.equal(ok.status, 0);
  assert.equal(ok.stdout, 'synthetic-key');
  assert.equal(ok.stderr, '');
  // Whitespace-bearing, missing and unreadable files exit 1 with no output:
  // the Claude mod treats that as "no key" and falls through to manual sources.
  await writeFile(keyFile, 'two words', { mode: 0o600 });
  const spaced = spawnSync(process.execPath, [cli.pathname, keyFile, '--emit-key'], { encoding: 'utf8', timeout: 3000 });
  assert.equal(spaced.status, 1);
  assert.equal(spaced.stdout, '');
  assert.equal(spaced.stderr, '');
  const missing = spawnSync(process.execPath, [cli.pathname, '/nonexistent/synthetic-key', '--emit-key'], { encoding: 'utf8', timeout: 3000 });
  assert.equal(missing.status, 1);
  assert.equal(missing.stdout, '');
  assert.equal(missing.stderr, '');
});

test('OpenCode attaches only installed approved skill and requests native compaction once', async () => {
  const hooks = new Map();
  const sent = [];
  globalThis.__jevTestSent = sent;
  const source = (await readFile(new URL('./opencode.mjs', import.meta.url), 'utf8'))
    .replace("from './controls.mjs'", `from '${new URL('./controls.mjs', import.meta.url).href}'`)
    .replace("from './cache-policy.mjs'", `from '${new URL('./cache-policy.mjs', import.meta.url).href}'`)
    .replace("import { execFile } from 'node:child_process';", `const execFile = (path,args,opts,cb) => ({stdin:{on(){},end(text){
      const input=JSON.parse(text); globalThis.__jevTestSent.push(input);
      const output=input.task==='skills'?{skill:'diagnosing-bugs'}:input.task==='compact'?{compact:true}:{model:{providerID:'openai',id:'gpt-6.1-sol',variant:'medium'}};
      queueMicrotask(()=>cb(null,JSON.stringify(output)));
    }}});`);
  const { default: plugin } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const domain = { hook: async (name, callback) => { hooks.set(name, callback); return { dispose: async () => {} }; } };
  let compacted = 0;
  const cleanup = await plugin.setup({ session: { ...domain, switchModel: async () => {}, compact: async () => { compacted++; } },
    permission: domain, tool: domain, shell: domain, skill: { list: async () => ({ data: [
      { id: 'local-debug', name: 'diagnosing-bugs', content: 'PRIVATE BODY' },
      { id: 'private', name: 'private-custom', content: 'PRIVATE BODY' },
    ] }) } });
  try {
    const event = { sessionID: 'test', prompt: { text: 'Debug a failure', skills: [{ id: 'explicit' }] } };
    await hooks.get('prompt')(event);
    assert.deepEqual(event.prompt.skills, [{ id: 'explicit' }, { id: 'local-debug' }]);
    assert.deepEqual(sent.find(i => i.task === 'skills').candidates, ['diagnosing-bugs']);
    assert.ok(!JSON.stringify(sent).includes('PRIVATE BODY'));
    const context = { sessionID: 'test', system: [], messages: ['x'.repeat(310000)], tools: {} };
    await hooks.get('context')(context);
    await hooks.get('context')(context);
    assert.equal(compacted, 1);
    assert.equal(sent.filter(i => i.task === 'compact').length, 1);
  } finally { await cleanup(); delete globalThis.__jevTestSent; }
});

test('Claude requests native compaction using only utilization, not transcript access', async () => {
  const source = await readFile(new URL('./claude/hooks/register.js', import.meta.url), 'utf8');
  const { register } = await import(`data:text/javascript,${encodeURIComponent(source)}`);
  const hooks = new Map();
  register((name, hook) => hooks.set(name, hook));
  let compacted = 0;
  const $ = { session: { usage: async () => ({ context: { percent: 85 } }), compact: async () => { compacted++; } },
    process: { run: async (argv, init) => {
      assert.deepEqual(JSON.parse(init.stdin), { task: 'compact', percent: 85 });
      return { exitCode: 0, stdout: '{"compact":true}' };
    } } };
  await hooks.get('turn.complete')($, { turnId: 'one', reason: 'answer' }, e => e);
  await hooks.get('turn.complete')($, { turnId: 'two', reason: 'answer' }, e => e);
  assert.equal(compacted, 1);
});
