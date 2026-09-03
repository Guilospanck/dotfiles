---
name: solve-pr-comments
description: Fetch PR review comments, evaluate and fix valid ones, update /pre-pr skill with learnings, run /pre-pr, and commit. One-shot workflow that handles the full PR feedback loop.
---

# Solve PR Comments

Fetch review comments from a GitHub PR, evaluate each one, fix the valid ones, update the `/pre-pr` skill so similar issues are caught proactively in future PRs, verify the build, run the updated `/pre-pr` skill, and commit.

## Phase 1: Fetch PR Comments

Invoke the `/pr-comments` skill (via the Skill tool) to fetch and display all PR comments. Use its formatted output as the input for Phase 2.

If no comments are found, report "No new PR comments" and stop.

## Phase 2: Evaluate Each Comment

For each comment, read the referenced file and line. Determine:

- **Valid — fix it**: The comment identifies a real bug, security issue, correctness problem, or meaningful improvement. Fix it.
- **Valid — skip**: The comment is technically correct but the fix is out of scope for this PR, too risky, or a refactor. Note why and move on.
- **Invalid / false positive**: The comment is wrong or based on a misunderstanding. Skip silently.

Present a table to the user before fixing:

| # | Comment summary | File:line | Verdict | Action |
|---|---|---|---|---|

Wait for user approval before proceeding with fixes. If the user says "just fix them all", proceed without the table.

## Phase 3: Fix Valid Comments

For each comment marked "fix it":
1. Read the relevant file
2. Make the fix
3. Verify the fix compiles (`go build`, `npx tsc --noEmit`)

## Phase 4: Update /pre-pr Skill

For each fixed comment, ask: **"Why didn't /pre-pr catch this?"**

Identify which agent (Dead Code, Code Reuse, Code Quality, Efficiency, Security) should have caught it, and what check was missing. Add the missing check to the appropriate agent section in `/pre-pr/skill.md` as a new numbered item. Write it generically — not specific to this PR, but as a general pattern that applies to any codebase.

## Phase 5: Verify and Run /pre-pr

1. Build: `go build ./...`, `go vet ./...`, `npx tsc --noEmit`
2. Tests: `npm run test` from the library directory
3. Run the updated `/pre-pr` skill (invoke via Skill tool) to catch any remaining issues

## Phase 6: Commit

Stage all fixed files and commit with a message summarizing what was addressed:

```
Address PR review: <brief summary of fixes>

<one line per fix explaining what changed and why>
```

## Notes

- Always read the actual file before deciding if a comment is valid — don't guess from the comment alone.
- When a comment suggests a code change (`suggestion` block), evaluate it critically — don't blindly apply it. The suggestion may be directionally correct but have issues.
- If a comment points out a pattern that repeats in multiple places, fix all occurrences, not just the one the reviewer pointed at.
- Comment fetching is delegated to the `/pr-comments` skill. All comments are fetched each time — use your judgment to skip comments already addressed in previous commits.
