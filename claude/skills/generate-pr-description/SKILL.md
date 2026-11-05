---
name: generate-pr-description
description: Use when the user asks for a PR description, PR summary, or wants to know what changed on a branch. Also use when creating a PR and a description is needed.
---

# Generate PR Description

Generate a succinct, bullet-pointed PR description by examining all commits and diffs on the current branch vs main.

## Process

1. **Get the PR commits and diff stat:**

```bash
git log --oneline origin/main...HEAD
git diff origin/main...HEAD --stat
```

2. **Dispatch an Explore agent** to scan the full diff (`git diff origin/main...HEAD`) and produce a concise breakdown grouped by area (new systems, integrations, fixes, UI changes, etc.)

3. **Write the description** as a flat bullet list under a `## Summary` heading. Each bullet should:
   - Start with a verb (Add, Fix, Implement, Remove, etc.)
   - Be one sentence — specific enough to understand the change, short enough to scan
   - Cover the *what* and *why*, not the *how*
   - Skip implementation details (file names, function names, line counts)

## Format

```markdown
## Summary

- Add [feature] that [does what] for [why]
- Fix [problem] by [approach]
- Remove [thing] because [reason]
```

## What NOT to do

- Don't list every commit as a separate bullet — group related commits into one point
- Don't include file paths or code snippets
- Don't write paragraphs — one line per bullet
- Don't add a test plan section unless asked
