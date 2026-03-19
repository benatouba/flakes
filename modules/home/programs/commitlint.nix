{ ... }:

{
  home.file.".commitlintrc.yaml".text = ''
    rules:
      body-leading-blank: [1, always]
      body-max-line-length: [2, always, 100]
      footer-leading-blank: [1, always]
      footer-max-line-length: [2, always, 100]
      header-max-length: [2, always, 100]
      subject-case:
        - 2
        - never
        - - sentence-case
          - start-case
          - pascal-case
          - upper-case
      subject-empty: [2, never]
      subject-full-stop: [2, never, "."]
      type-case: [2, always, lower-case]
      type-empty: [2, never]
      type-enum:
        - 2
        - always
        - - build
          - chore
          - ci
          - docs
          - feat
          - fix
          - perf
          - refactor
          - revert
          - style
          - test
    prompt:
      questions:
        type:
          description: "Select the type of change that you're committing"
          enum:
            feat:
              description: A new feature
              title: Features
              emoji: "\u2728"
            fix:
              description: A bug fix
              title: Bug Fixes
              emoji: "\U0001F41B"
            docs:
              description: Documentation only changes
              title: Documentation
              emoji: "\U0001F4DD"
            style:
              description: "Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)"
              title: Styles
              emoji: "\U0001F485"
            refactor:
              description: A code change that neither fixes a bug nor adds a feature
              title: Code Refactoring
              emoji: "\u267B\uFE0F"
            perf:
              description: A code change that improves performance
              title: Performance Improvements
              emoji: "\u26A1"
            test:
              description: Adding missing tests or correcting existing tests
              title: Tests
              emoji: "\u2705"
            build:
              description: "Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)"
              title: Builds
              emoji: "\U0001F3D7\uFE0F"
            ci:
              description: "Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)"
              title: Continuous Integrations
              emoji: "\U0001F680"
            chore:
              description: "Other changes that don't modify src or test files"
              title: Chores
              emoji: "\u2B1B"
            revert:
              description: Reverts a previous commit
              title: Reverts
              emoji: "\U0001F5D1"
        scope:
          description: "What is the scope of this change (e.g. component or file name)"
        subject:
          description: "Write a short, imperative tense description of the change"
        body:
          description: Provide a longer description of the change
        isBreaking:
          description: Are there any breaking changes?
        breakingBody:
          description: "A BREAKING CHANGE commit requires a body. Please enter a longer description of the commit itself"
        breaking:
          description: Describe the breaking changes
        isIssueAffected:
          description: Does this change affect any open issues?
        issuesBody:
          description: "If issues are closed, the commit requires a body. Please enter a longer description of the commit itself"
        issues:
          description: 'Add issue references (e.g. "fix #123", "re #123".)'
  '';
}
