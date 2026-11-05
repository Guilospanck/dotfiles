---
name: pr-comments
description: Fetch and display comments from the GitHub pull request on the current branch. Use when the user wants to see PR review comments, code review feedback, or issue-level comments.
---

# PR Comments

Fetch and display all comments from the GitHub PR for the current branch.

## Steps

1. Get PR info:
   ```bash
   gh pr view --json number,headRepository
   ```

2. Fetch PR-level (issue) comments:
   ```bash
   gh api /repos/{owner}/{repo}/issues/{number}/comments
   ```

3. Fetch review comments (code-level):
   ```bash
   gh api /repos/{owner}/{repo}/pulls/{number}/comments
   ```
   Pay attention to: `body`, `diff_hunk`, `path`, `line`, `original_line`.

4. If a comment references code, consider fetching it:
   ```bash
   gh api /repos/{owner}/{repo}/contents/{path}?ref={branch} | jq .content -r | base64 -d
   ```

5. Parse and format all comments. Return ONLY the formatted comments.

## Output Format

```
## Comments

[For each comment thread:]
- @author file.ts#line:
  ```diff
  [diff_hunk from the API response]
  ```
  > quoted comment text

  [any replies indented]
```

If there are no comments, return "No comments found."

## Rules

- Only show actual comments, no explanatory text
- Include both PR-level and code review comments
- Preserve threading/nesting of replies
- Show file and line number context for code review comments
- Use jq to parse JSON responses from the GitHub API
