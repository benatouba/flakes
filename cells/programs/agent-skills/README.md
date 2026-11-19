# Managed agent skills

The ThinkPad desktop installs one directory per skill under `~/.claude/skills`.
Claude Code and OpenCode both discover that location; avoid adding a second copy
under an OpenCode-specific directory. The catalog refuses to take over existing
unmanaged paths. Move a conflicting skill elsewhere yourself before activation.

The allowlist lives in `cells/programs/agent-skills.nix`. `nix flake update`
refreshes upstream sources; `flake.lock` records exactly what will be built. To
refresh only the independent skill sources, use:

```sh
nix flake update mattpocock-skills vercel-skills cloudflare-skills \
  ai-developer-guide scientific-agent-skills openai-skills
```

`agent-browser` updates with its Nixpkgs package. Review changes to the selected
skill instructions and bundled scripts before deploying an updated lockfile.
Missing `SKILL.md` files in the selected upstream source directories fail the
Home Manager build, as do changes to their `name` field.
New upstream skill IDs require an allowlist change.

Cloudflare's `cloudflare` skill includes defensive WAF guidance. The audit skill
and Cloudflare tooling are not installed by this catalog. The `ai-developer-guide`
wrapper reads bundled Markdown and does not enable MCP or install review commands.
OpenAI's notebook skill uses the shared skill path and the project's Python
instead of bootstrapping a separate notebook environment.

Use `/ai-developer-guide` and `/climate-data-cmip`, `/climate-model-evaluation`,
or `/climate-paper-planning` in Claude Code. In OpenCode, use `@` instead of `/`.
The climate skills are local guidance, not independently validated. Scientific
skills use the project's environment; this catalog adds no scientific runtime.
