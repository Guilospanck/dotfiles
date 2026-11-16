---
name: weekly-update
description: Use when the user asks for a weekly summary, status update, or changelog of work done on the main branch — generates a stakeholder-friendly Slack message
---

# Weekly Update

Generate a concise, stakeholder-friendly weekly summary from git history, grouped by impact category.

## Steps

1. Get the last 7 days of commits on main:
   ```bash
   git log --oneline --since="7 days ago" main
   ```

2. Analyze all commits (not just merges) and group into these categories:
   - **New Features** — new user-facing or system capabilities
   - **Bug Fixes** — corrections to broken behavior
   - **Internal Improvements** — refactors, tooling, infrastructure, test coverage, naming conventions

3. Write each bullet as a concise, outcome-focused statement. Avoid PR numbers, commit hashes, or implementation-only jargon. The audience is technical stakeholders — they care about *what changed and why*, not *which files were touched*.

4. Format for Slack using bold section headers and plain bullet points.

## Output Format

```
*[Project Name] — Weekly Update*

*New Features*
- [outcome-focused bullet]

*Bug Fixes*
- [outcome-focused bullet]

*Internal Improvements*
- [outcome-focused bullet]
```

## Guidelines

- Omit empty categories
- Merge related commits into a single bullet
- Lead with the most impactful items in each category
- Keep bullets to one line when possible
- Do not describe work by PR — group by what was achieved
