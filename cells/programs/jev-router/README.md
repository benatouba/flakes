# Jev routing and bounded controls

The personal Home Manager branch exposes a runtime-credential helper only when
the existing `typesafe_api_key` SOPS entry is configured. The desktop branch
then installs an OpenCode plugin and wraps the repository's Claude Code CLI
with two plugins: the vendored upstream selector (`dominicrico/jev-router`,
pinned by commit) and the local `jev-controls` mod (guards, allowlist clamp,
compaction scheduling). Without the personal branch or the key,
neither integration is enabled. No new secret, provider, proxy, package input or listening port is
introduced. Activation and restarting existing clients are separate operations.

## Routing policy

| Complexity | OpenCode | Claude Code |
| --- | --- | --- |
| Simple | OpenAI GPT-6.1 Sol, low reasoning | Claude Haiku 5.5 |
| Normal / fallback | OpenAI GPT-6.1 Sol, medium reasoning | Claude Sonnet 5.5 |
| Complex | OpenAI GPT-6.1 Terra, high reasoning | Claude Opus 5.5 |

These are explicit policy choices, not benchmark or pricing claims. Model IDs
are intentionally fixed, not automatically upgraded aliases. Review both the
helper and client allowlists when a new generation is adopted. Account access
to these models is required; this configuration does not provision it or change
provider authentication. An unavailable model is not replaced with an older
generation. A failed, malformed, low-confidence or timed-out Jev decision keeps
the current allowed model: OpenCode makes no switch, and the vendored Claude
selector leaves the session model to the local clamp. Classification has a
four-second network timeout, no retries, a 16 KiB response limit and a 0.6
confidence threshold.

OpenCode classifies at prompt admission and switches the session's model before
generation. Model requests, including auxiliary requests, reject non-allowlisted
providers or model IDs while the plugin is active. Concurrent/queued prompts
still use OpenCode's session-wide selection semantics; this is not an atomic
per-message model override. A project configuration or another plugin can
conflict with it. Test interactive steering/queues before depending on them.

### Warm-cache stickiness (OpenCode)

Before switching, the plugin consults native step telemetry
(`session.step.started/ended`): the current model is *warm* when a step
completed within the last five minutes, carries at least 8,000 context tokens
and recorded a cache read. While warm, a classifier downgrade or an upgrade
below 0.7 confidence becomes an in-place effort change on the cached model
instead of a model switch; an upgrade at 0.7 or above pays the cache reset.
Effort changes keep the prompt prefix intact, so a cheap task no longer throws
away a live cache. The event stream is volatile (loss is possible), so missing
telemetry only disables stickiness — it never fakes warmth, and it never
overrides the allowlist.

### Vendored Claude selector and the local clamp

Claude Code routing is handled by the vendored upstream selector, fetched at a
pinned commit with `fetchFromGitHub` (no new flake input) and patched at build
time: conversation history and subagent task text are hard-disabled so only
task prompt text is ever classified, the model pool is restricted to the 5.5
trio, and the TypeSafe key is resolved through the local
`jev-control --emit-key` helper instead of environment variables or the
settings store. The repository's own mod was renamed to `jev-controls` and no
longer classifies: it applies a final 5.5 allowlist clamp to main-loop steps,
keeps native compaction scheduling and hosts the tool/prompt guards. Exactly
one selector owns each turn; a main-loop model outside the trio fails closed to
Sonnet 5.5, while subagent requests keep the model their agent configuration
chose (explicit local policy, not routing output). The mod does not change tool
permissions, user settings or credentials. Both plugins apply to the wrapped
terminal CLI, not independent desktop/editor/cloud installations. The selector
picks agent-loop models, not every internal auxiliary model. Claude may skip
failed/disabled hooks: neither plugin is an organizational security boundary,
and a disabled plugin cannot enforce its allowlist.

## Medium-privacy boundary and safeguards

Only the new prompt text is used for routing, never the conversation history,
attachment objects, file contents read from disk, tool arguments or results.
Inline code fences, URLs/URL credentials, emails, mentions and common credential
patterns are removed locally; the result is limited to 4,000 characters. Prompts
larger than 65,536 characters are not sent. Pasted/inline text is still prompt
text: heuristics cannot guarantee removing arbitrary secrets, private prose or
all forms of personal data. Do not paste sensitive information into a prompt
that will be classified. The selected coding model receives the client's usual
coding context; this restriction is on the additional Jev request only.

The helpers read the existing SOPS key only at runtime, do not export it into
the client's environment, and never log prompts, keys, responses or routing
errors. The user confirmed a directly issued TypeSafe credential: helpers and
the existing MCP wrapper are pinned to `https://api.typesafe.ai/v1/systemone`.
Key shape cannot select a community gateway; redirects and endpoint overrides
are forbidden for helper requests. The vendored Claude mod resolves its key
through the local `jev-control --emit-key` helper at request time (stdout into
mod memory only), so the key never appears in Claude's environment, settings
store or command lines.
Upstream retention, processing region, billing and deletion are not controlled
by this configuration and must be checked with the existing Jev provider.
No local routing history is persisted or backed up.

The separately exposed Jev MCP tools retain their existing approval rules.
Manual MCP tool calls are not passed through this redactor; approve only the
data you intend to send. No tool gets automatic permission from a Jev decision.

## Skill detection and compaction

The optional public catalog is intentionally small: `diagnosing-bugs`, `tdd`,
`code-review`, `opencode`, and `writing-for-agents`. Only locally available
candidates can be selected. TypeSafe receives their fixed public labels and
descriptions plus the redacted latest prompt, never installed skill bodies,
private descriptions, IDs or paths. Errors/uncertainty abstain.

OpenCode attaches the selected installed skill through the native prompt draft,
preserving explicit attachments. Claude's `UserPromptSubmit` hook discovers
these names under project/user Claude skills and user `.agents/skills`, then
adds an advisory suggestion: it does not execute commands or force skill loading.
Other plugin/builtin/custom skill locations are not indexed in this Claude adapter.
Neither selector suppresses mandatory instructions or replaces skill auditing.

Compaction remains native and generative. OpenCode requests a timing decision
at 300,000 context characters; Claude checks native context utilization at turn
completion and asks at 80%. TypeSafe receives only character/message counts or
utilization, not transcript text. Positive decisions request native compaction;
failure leaves automatic overflow handling intact. Requests have a five-minute
cooldown. This is scheduling, not the community projects' more intrusive
Jev-selected transcript pruning or checkpoint replacement.

## Tool and leak screening

Local checks recognize common credential formats and sensitive credential
paths before remote classification. Suspected credential access/disclosure is
blocked. Additional Jev tool decisions receive only five booleans: secret,
sensitive path, network, destructive operation, and execution indirection.
No arguments, commands, destinations, file contents or history are transmitted.
This deliberately limits semantic risk assessment: flags cannot describe what
an arbitrary program will do.

- OpenCode permission evaluation can only tighten allow/ask to ask/deny. Shell
  resources may be partial, so **all shell permissions now require approval**,
  even commands previously broadly allowed. Tool execution and native shell
  creation also check full input locally for credential/path patterns.
- Claude `PreToolUse` checks built-in/MCP tool input. Native asks/denies remain;
  risk flags or unavailable classification require ask, and local sensitive
  findings deny. Startup, malformed output and timeout use `onFailure: block`;
  malformed helper input exits 2. Unattended callers must not auto-answer asks.
- OpenCode additionally blocks recognized credentials in primary, compaction,
  title and generate context, final HTTP bodies and outbound WebSocket frames.
  It does not restore secret placeholders into tools. A scanned string/input
  larger than one million characters is refused rather than scanned partially.
- Claude has **no full outgoing-model-context scanner in this integration**.
  Its checks restrict tool inputs, not already-loaded files, all tool results,
  model attachments or existing transcript contents.

These are heuristic guards, **not a sandbox or complete DLP**. Unknown, encoded,
fragmented or binary secrets, indirect program behavior, arbitrary plugin code,
disabled hooks, plugin ordering and data already sent/persisted remain gaps.
False positives (including synthetic credential examples) require removing the
suspect text, not automatically bypassing the check. Existing transcripts/logs
are not scrubbed; provider retention and region remain external decisions.

The community projects were reviewed: `dominicrico/jev-router` is now vendored
for Claude model selection only — fetched at a pinned commit with
`fetchFromGitHub` (no new flake input), patched at build time for payload and
pool policy, with its key resolved through the SOPS helper; its upstream test
suite passes via `claude plugin test` against a pristine checkout. The
remaining candidates are not installed: Jevvy's auto-approval conflicts with
this policy; jev-guard's OpenCode adapter is legacy; masking/restoration and
transcript-pruning candidates exceed this privacy boundary. These adapters keep
the reviewed native hook seams for everything except Claude model selection.
The research notes under `docs/research/` record the project assessment when
those local notes are available. No community security audit is inherited.

## Validation and recovery

Run `node --test cells/programs/jev-router/*.test.mjs` for offline tests,
or build `path:.#checks.x86_64-linux.jev-router`. While new module and test
files are still untracked, use the `path:.` form: git flakes exclude untracked
files, so the plain `.#` form cannot see them. The tests use only synthetic
keys, mock HTTP responses and client hook doubles, not real model completions.
Validate a staged copy of each generated plugin with
`claude plugin validate PATH --strict`, and run the vendored selector's own
suite with `claude plugin test` in a pristine pinned checkout. Directory
profile checks (README/license) do not apply to these private local plugins;
the packaged controls plugin includes its README, and the vendored selector
ships its MIT license.

Before activation, build the named host's Home Manager activation package.
After an explicitly approved activation, restart the clients and test a
synthetic prompt in each; no live routing result is established by a build.
To disable routing and controls declaratively, set `my.jev.router = lib.mkForce null` in the
applicable Home Manager module, rebuild and restart the clients. This keeps the
existing MCP integration. Keep the previous system/Home Manager generation for
rollback; no database or authentication-file edits are needed. Setting only
`my.jev.control` to null is not a supported disable switch: active clients must
never be left with a missing guard executable. No live blocking or model
completion has been established by these offline tests/builds.
