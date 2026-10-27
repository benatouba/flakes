import { execFile } from 'node:child_process';
import { localRisk, assertNoSecret, skills } from './controls.mjs';
import { cachePlan } from './cache-policy.mjs';

const allowed = new Set(['gpt-6.1-sol', 'gpt-6.1-terra']);

export function review(input) {
  return new Promise(resolve => {
    const child = execFile('@control@', [], { timeout: 6000, maxBuffer: 16384 }, (error, stdout) => {
      try { if (!error) return resolve(JSON.parse(stdout)); } catch { /* No payload logging. */ }
      resolve({ effect: 'ask', skill: null, compact: false });
    });
    child.stdin.on('error', () => {});
    child.stdin.end(JSON.stringify(input));
  });
}

export function classify(prompt) {
  return new Promise(resolve => {
    const child = execFile('@router@', [], { timeout: 6000, maxBuffer: 16384 }, (error, stdout) => {
      try {
        const parsed = JSON.parse(stdout);
        const result = parsed.model;
        if (!error && result.providerID === 'openai' && allowed.has(result.id)
          && ['low', 'medium', 'high'].includes(result.variant)
          && Number.isFinite(parsed.confidence) && parsed.confidence >= 0.6 && parsed.confidence <= 1) {
          return resolve({ ...result, confidence: parsed.confidence });
        }
      } catch { /* No upstream payloads or prompts in logs. */ }
      // Fail closed: null keeps the session's current allowed model.
      resolve(null);
    });
    child.stdin.on('error', () => {});
    child.stdin.end(JSON.stringify({ client: 'opencode', prompt }));
  });
}

// Plugin.define is an identity function in OpenCode 2.1.1. A plain definition
// avoids adding an npm dependency solely for that function.
export default {
  id: 'jev-router',
  async setup(ctx) {
    const pending = new Map();
    const checkpoints = new Map();
    // Cache-warmth telemetry: assistant message -> step start, session -> last
    // completed step. Bounded bookkeeping only; no prompt or transcript content.
    const stepModels = new Map();
    const steps = new Map();
    const registrations = [];
    const hook = async (domain, name, fn) => { registrations.push(await domain.hook(name, fn)); };

    const recordStep = event => {
      try {
        if (!event || typeof event.type !== 'string' || !event.data
          || typeof event.data.sessionID !== 'string') return;
        const data = event.data;
        if (event.type === 'session.step.started') {
          const model = typeof data.model === 'string' ? data.model : data.model?.id;
          if (typeof data.assistantMessageID !== 'string' || typeof model !== 'string') return;
          stepModels.set(data.assistantMessageID, { sessionID: data.sessionID, model });
          if (stepModels.size > 128) stepModels.delete(stepModels.keys().next().value);
          return;
        }
        if (event.type !== 'session.step.ended') return;
        const started = stepModels.get(data.assistantMessageID);
        stepModels.delete(data.assistantMessageID);
        if (!started || started.sessionID !== data.sessionID) return;
        const parts = [data.tokens?.input, data.tokens?.output, data.tokens?.reasoning,
          data.tokens?.cache?.read, data.tokens?.cache?.write];
        // Missing usage is unknown, not zero warmth evidence.
        if (parts.some(value => !Number.isFinite(value))) return;
        steps.set(data.sessionID, {
          model: started.model,
          at: Date.now(),
          contextTokens: parts.reduce((sum, value) => sum + value, 0),
          cacheRead: parts[3],
        });
        if (steps.size > 128) steps.delete(steps.keys().next().value);
      } catch { /* Telemetry only informs stickiness; never break a turn. */ }
    };

    // The event stream is volatile and spans locations: a lost event merely
    // disables stickiness for that session, it never fakes cache warmth.
    let stopEvents = () => {};
    if (typeof ctx.event?.subscribe === 'function') {
      const iterator = ctx.event.subscribe()[Symbol.asyncIterator]();
      let stopped = false;
      stopEvents = () => {
        stopped = true;
        try { iterator.return?.(); } catch { /* Ending the stream is best effort. */ }
      };
      (async () => {
        try {
          for (;;) {
            const { value, done } = await iterator.next();
            if (done || stopped) break;
            recordStep(value);
          }
        } catch { /* Missing events only weaken stickiness. */ }
      })();
    }

    const prompt = await ctx.session.hook('prompt', async event => {
      const previous = pending.get(event.sessionID) ?? Promise.resolve();
      const current = previous.catch(() => {}).then(async () => {
        const target = await classify(event.prompt.text);
        if (target) {
          const plan = cachePlan(target, steps.get(event.sessionID));
          await ctx.session.switchModel({
            sessionID: event.sessionID,
            model: { providerID: 'openai', id: plan.model, variant: plan.variant },
          });
        }
        const { data: available } = await ctx.skill.list();
        const candidates = available.filter(s => s.autoinvoke !== false && Object.hasOwn(skills, s.name));
        const result = await review({ task: 'skills', prompt: event.prompt.text, candidates: candidates.map(s => s.name) });
        const selected = candidates.find(s => s.name === result.skill);
        if (selected && !(event.prompt.skills ?? []).some(s => s.id === selected.id)) {
          event.prompt.skills = [...(event.prompt.skills ?? []), { id: selected.id }];
        }
      });
      pending.set(event.sessionID, current);
      try { await current; } finally {
        if (pending.get(event.sessionID) === current) pending.delete(event.sessionID);
      }
    });
    // Also guard continuations and auxiliary requests. Never silently fall back
    // to an older generation or another provider when model selection fails.
    const guard = await ctx.session.hook('model.request', event => {
      if (event.model.providerID !== 'openai' || !allowed.has(event.model.id)) {
        throw new Error('Jev routing requires an allowed OpenAI 6.1 model.');
      }
    });
    await hook(ctx.permission, 'evaluate', async event => {
      if (event.effect === 'deny') return;
      const risk = localRisk(event.resources);
      // Shell permission resources can describe only part of a compound command.
      // Do not infer full-program safety from that partial string.
      if (event.action === 'shell') risk.indirect = true;
      const result = await review({ task: 'tool', risk });
      if (risk.secret || risk.sensitivePath) result.effect = 'deny';
      else if ((risk.network || risk.destructive || risk.indirect) && result.effect !== 'deny') result.effect = 'ask';
      if (result.effect === 'deny' || (event.effect === 'allow' && result.effect !== 'unchanged')) {
        event.effect = result.effect === 'deny' ? 'deny' : 'ask';
        event.message = 'Local/Jev risk screening requires restriction.';
      }
    });
    await hook(ctx.tool, 'execute.before', event => {
      const risk = localRisk(event.input);
      if (risk.secret || risk.sensitivePath) throw new Error('Local Jev guard blocked suspected credential access or disclosure.');
    });
    await hook(ctx.shell, 'create.before', event => {
      const risk = localRisk(event.command);
      if (risk.secret || risk.sensitivePath) throw new Error('Local Jev guard blocked suspected credential access or disclosure.');
    });
    for (const kind of ['context', 'compaction', 'title', 'generate']) {
      await hook(ctx.session, kind, async event => {
        assertNoSecret([event.system, event.messages, event.tools]);
        if (kind !== 'context') return;
        const characters = JSON.stringify(event.messages).length;
        const now = Date.now();
        if (characters < 300000 || now - (checkpoints.get(event.sessionID) ?? 0) < 300000) return;
        checkpoints.set(event.sessionID, now);
        // Bound bookkeeping; no transcript or classifier answer is retained.
        if (checkpoints.size > 128) checkpoints.delete(checkpoints.keys().next().value);
        const result = await review({ task: 'compact', characters, messages: event.messages.length });
        if (result.compact === true) await ctx.session.compact({ sessionID: event.sessionID });
      });
    }
    await hook(ctx.session, 'http.request', async event => {
      if (event.request.body) assertNoSecret(await event.request.clone().text());
    });
    await hook(ctx.session, 'experimental.ws.send', event => { assertNoSecret(event.frame); });
    return async () => {
      await prompt.dispose(); await guard.dispose();
      for (const registration of registrations) await registration.dispose();
      stopEvents();
      pending.clear(); checkpoints.clear(); stepModels.clear(); steps.clear();
    };
  },
};
