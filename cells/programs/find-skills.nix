{ inputs, ... }:
{
  # Vercel's find-skills: discover/install agent skills via `npx skills`.
  # The `vercel-skills` flake input tracks the upstream default branch, so
  # `nix flake update vercel-skills` always pulls the most recent version.
  # Only this skill is linked; nothing else from the repo is wanted.
  config.my.branches.desktop.hmModules = [
    (
      { ... }:
      {
        home.file.".claude/skills/find-skills" = {
          source = "${inputs.vercel-skills}/skills/find-skills";
          force = true;
        };
      }
    )
  ];
}
