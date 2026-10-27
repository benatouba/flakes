import { access, readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { control, localRisk, skills } from './controls.mjs';

// Runtime credential hand-off for the vendored Claude mod. The SOPS path
// arrives as argv[2]; only validated key bytes reach stdout, never argv-echoed,
// logged, or exported into the environment where child processes could read it.
if (process.argv[3] === '--emit-key') {
  try {
    const key = (await readFile(process.argv[2], 'utf8')).trim();
    if (!key || key.length > 4096 || /\s/.test(key)) process.exitCode = 1;
    else process.stdout.write(key);
  } catch { process.exitCode = 1; }
} else {
  try {
    const chunks = [];
    let size = 0;
    for await (const chunk of process.stdin) {
      size += chunk.length;
      if (size > 1500000) throw new Error('Oversized input');
      chunks.push(chunk);
    }
    const input = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    const options = { keyFile: process.argv[2] };
    let output;
    if (process.argv[3] === '--tool-hook') {
      if (input.hook_event_name !== 'PreToolUse' || typeof input.tool_name !== 'string' || !input.tool_input) throw new Error('Invalid tool event');
      const result = await control({ task: 'tool', risk: localRisk(input.tool_input) }, options);
      output = result.effect === 'unchanged' ? {} : { hookSpecificOutput: {
        hookEventName: 'PreToolUse', permissionDecision: result.effect,
        permissionDecisionReason: 'Local/Jev screening requires restriction. No tool arguments were sent to TypeSafe.',
      } };
    } else if (process.argv[3] === '--prompt-hook') {
      if (input.hook_event_name !== 'UserPromptSubmit' || typeof input.prompt !== 'string' || typeof input.cwd !== 'string') throw new Error('Invalid prompt event');
      const candidates = [];
      for (const id of Object.keys(skills)) {
        for (const root of [join(input.cwd, '.claude', 'skills'), join(homedir(), '.claude', 'skills'), join(homedir(), '.agents', 'skills')]) {
          try { await access(join(root, id, 'SKILL.md')); candidates.push(id); break; } catch { /* Not installed. */ }
        }
      }
      const { skill } = await control({ task: 'skills', prompt: input.prompt, candidates }, options);
      output = skill ? { hookSpecificOutput: { hookEventName: 'UserPromptSubmit',
        additionalContext: `Optional relevant skill: ${skill}. Load through the normal Skill tool if useful. Preserve explicit user choices, mandatory instructions and all tool approvals.` } } : {};
    } else {
      output = await control(input, options);
    }
    process.stdout.write(JSON.stringify(output));
  } catch {
    // PreToolUse's onFailure:block makes malformed input/startup failure blocking.
    // Exit 2 also blocks in hosts that implement the ordinary hook exit contract.
    process.stderr.write('Jev control unavailable; protected operation was not approved.\n');
    process.exitCode = 2;
  }
}
