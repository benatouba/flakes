# Global development conventions

Apply these conventions to every software project unless the repository’s own instructions explicitly require a different approach. Project-local instructions refine these defaults; they do not justify silently bypassing security, privacy, validation, or reproducibility requirements.

## Environment management

- For ordinary application, library, web, data, and tooling projects, use a repository-managed `devenv.nix` as the canonical development environment.
- Prefer entering and executing project tooling through `devenv shell` (or the repository’s documented equivalent). Declare development tools, language runtimes, databases, services, environment variables, scripts, checks, and test dependencies in `devenv.nix` rather than relying on undeclared global machine state.
- If a project lacks `devenv.nix`, propose a minimal project-appropriate `devenv.nix` before adding ad-hoc environment setup. Preserve existing environment tooling if the repository explicitly standardizes on something else.
- Do not add global package-manager installs, `nix profile install` dependencies, manual PATH mutations, or unpinned bootstrap downloads as a substitute for a reproducible project environment.
- Exception: a NixOS flakes/infrastructure repository is managed through its existing Nix shell or the repository’s documented Nix development environment, not through `devenv.nix`. Do not introduce or require `devenv.nix` in a NixOS flakes repository unless explicitly requested.

## Python

- Use `uv` as the default Python package manager, resolver, virtual-environment manager, and command runner.
- Prefer a `pyproject.toml` with a committed `uv.lock` for application and library projects. Manage dependencies through `uv add`, `uv remove`, and `uv sync`; run project commands through `uv run`.
- Do not use `pip install`, `pip freeze`, `requirements.txt`, Poetry, Pipenv, Conda, or manually activated virtual environments for new work unless the repository already requires one of them or the user explicitly requests it.
- Do not rely on a globally installed Python package. Put Python version and dependencies under project management and make commands reproducible in the project environment.
- Keep runtime, development, test, lint, type-checking, and optional dependencies explicit. Update the lock file whenever dependency resolution changes.
- Prefer typed Python, explicit public interfaces, isolated side effects, structured/redacted logging, input validation, and focused automated tests.

## JavaScript and TypeScript

- Use `pnpm` as the default JavaScript/TypeScript package manager and command runner.
- Commit and maintain `pnpm-lock.yaml`. Use `pnpm install`, `pnpm add`, `pnpm remove`, `pnpm run`, `pnpm exec`, and `pnpm dlx` as appropriate.
- Do not use npm, Yarn, Bun, or globally installed packages for new work unless the repository already requires one of them or the user explicitly requests it.
- Declare the intended package-manager version via the repository’s established mechanism, preferably the `packageManager` field in `package.json`; enable and use Corepack where appropriate to honor that version.
- Avoid mixing lock files or package managers. If an existing project uses a different manager, preserve it unless migrating intentionally with explicit scope and validation.
- Use TypeScript where the repository supports it. Keep dependencies minimal, maintainable, license-compatible, and pinned through the lock file.

## Cross-language dependency rules

- Before adding a dependency, assess whether the standard library, existing dependency set, or a smaller maintained alternative already solves the need.
- Check maintenance, license, platform compatibility, transitive/supply-chain impact, security history, and privacy/data-sharing implications before adding a package or service SDK.
- Do not add dependencies, update lock files broadly, or upgrade unrelated packages as incidental changes.
- Keep credentials, tokens, generated local state, virtual environments, build outputs, and secret configuration out of version control. Provide documented example configuration without real secrets.

## Verification

- Run commands from the project’s declared environment and use the project’s package manager.
- Before declaring work complete, run or state the relevant formatting, linting, type checking, tests, build/evaluation, and security checks.
- If a dependency, runtime, lock file, or environment definition changes, validate installation/synchronization and the affected build/test path.
