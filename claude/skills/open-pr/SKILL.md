---
name: open-pr
description: Write a PR description using conversation context and open PR creation in browser.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

<!-- This is a starting point. Customize the template and guidelines to match your team's PR conventions. -->

## Commit uncommitted changes

1. Run `git status` to check for uncommitted changes
2. If changes exist, commit them before proceeding (follow the commit style visible in `git log` and the project's CLAUDE.md)

## Gather context

1. Get the base branch (usually `main` or `master`)
2. Get the diff: `git diff <base>...HEAD`
3. Get commit messages: `git log <base>...HEAD --format="%s"`
4. Read changed files to understand the broader context

## Write PR description

Follow the `generate-pr-description` skill for the format; it is the single source of truth. Use the conversation context to inform it.

## Create the PR

1. Write a short PR title (max 72 characters)

2. Ensure the branch is pushed:
   ```bash
   git push -u origin HEAD
   ```

3. Open PR creation in browser (do NOT create directly):
   ```bash
   gh pr create --web --title "<title>" --body "<body>"
   ```
