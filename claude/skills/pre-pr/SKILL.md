---
name: pre-pr
description: Use when ready to open a PR, before committing final changes. Reviews changed code for dead code, stale docs/comments, code quality, efficiency, and security issues, fixes them, then generates a copy-paste PR description.
---

# Pre-PR Review and Description

Final cleanup pass on all changed files before opening a PR. Finds and fixes issues, then produces a ready-to-paste PR description.

## Phase 1: Identify Changes

Run `git diff` (or `git diff HEAD` if there are staged changes) to see what changed. If there are no git changes, review the most recently modified files from the conversation.

Also run `git log <base>..HEAD --oneline` (base is usually `main`) to understand the full commit history for the PR description.

If the diff is large, save it to a file (for example in the scratchpad directory) so reviewers can read it by path.

## Phase 2: Review

Review the diff in the areas below. Do it yourself when the diff is small. Delegate to subagents only when the diff is large enough to benefit; in that case give each subagent the diff file path (not pasted content), set the model explicitly (Sonnet by default), and tell it to stop any background shells before it reports.

### Area 1: Dead Code and Stale Docs

For each changed file:

1. **Dead code**: unused fields, unreachable branches, unused imports and variables, functions only called from deleted code, enum/union variants never referenced, and orphaned state or UI left behind by a removed feature (timers, markers, DOM elements, their creation and cleanup).
2. **Stale comments and docs**: doc comments that no longer match the signature or behavior, TODO/FIXME for things already done, comments describing code that changed or was removed, inline comments that misdescribe the mechanism.
3. **Stale or incomplete re-exports**: barrel/index files exporting removed or renamed symbols, or missing new public symbols that sibling modules already re-export.

### Area 2: Code Reuse

For each change, search the codebase for existing utilities that could replace newly written code. Flag new functions that duplicate existing functionality and inline logic (string manipulation, path handling, ad-hoc type guards) that an existing helper covers.

### Area 3: Code Quality

Find hacky patterns, including:

- redundant or derivable state, duplicate types, near-duplicate code blocks;
- raw strings where constants or enums exist;
- open/close pairs without a guaranteed close (listeners, locks, timers, subscriptions), and classes that start long-lived work without a stop/dispose API;
- handlers that do not filter to the intended trigger, or that intercept events meant for local editable elements;
- side effects (state mutation, timestamps, messages) before validation succeeds, and state not rolled back after failed or dropped operations;
- ignored error or success return values;
- module-level mutable state shared across instances;
- parameters accepted but not controlling behavior;
- boundary errors in numeric range conversions and size/length semantics across language boundaries;
- check-then-act races, including unlock-call-relock patterns, and concurrent writes to a shared output;
- write-path identifier changes not mirrored in read-path comparisons, and exact-equality checks on identifiers that now have several valid formats;
- constructors that call methods before assigning all fields, and validators that silently accept duplicate keys;
- tests that stub the unit under test, instead of only its external dependencies.

### Area 4: Efficiency

Find redundant calls, duplicate or N+1 work, unbounded data structures and leaks, locks held across I/O or external calls, blocking work inside event callbacks, unbounded concurrent subprocess or goroutine spawning, duplicate event emission across layers, and limits enforced late instead of at the parser.

### Area 5: Security

Review for common vulnerability classes (OWASP top 10) and any domain-specific risks of the touched code: injection (HTML, SQL, shell), missing validation of untrusted input at boundaries, secrets or user content in code or logs, missing sender/origin/permission checks, resource exhaustion triggered by remote input, unsafe access to externally parsed objects, insecure defaults (transport, CORS, headers), unguarded use of APIs that may throw or be unsupported, and protocol or content-type names that no longer describe what they carry.

### Area 6: Documentation Staleness

Validate that project documentation (README.md, ARCHITECTURE.md, and any other .md files in the repo, excluding CLAUDE.md, AGENTS.md, and skill files) is consistent with the current codebase. For each changed file in the diff:

1. **API signature drift**: If a public function/method/class was added, removed, renamed, or had its signature changed, check whether any README or doc file references it. Flag docs that show the old signature, wrong parameter types, or missing new APIs.
2. **Async/sync mismatch in examples**: If a function's return type changed (for example from a promise to a plain value or vice versa), check that code examples in docs use or omit `await` correctly.
3. **New exports not documented**: If an index/barrel file gained new exports, check whether the relevant README lists them. Flag undocumented public API surface.
4. **Removed features still documented**: If code was deleted (files, classes, functions), check whether docs still reference them.
5. **Architecture diagrams out of date**: If the layer structure changed (new modules, new message types), check whether architecture docs reflect the change.
6. **Project structure trees**: If files/directories were added or removed, check whether any project structure tree in docs matches the actual filesystem.
7. **Dependency/tooling claims**: If dependencies changed, check whether docs still claim correct dependencies.
8. **Per-component docs**: For changes to a sub-project or service with its own README, check that it matches the current images, CLI commands, environment variables, and architecture.

For each finding, report the doc file path, the specific section, and what's wrong. Include a suggested fix.

### Cross-cutting: Sibling Consistency

Before fixing, apply these two mandatory cross-checks to the findings:

1. **Sibling file check**: For every issue found in a file, search for sibling files that follow the same pattern (other handler implementations, other modules with the same interface). If the issue exists in the changed file, it very likely exists in its siblings too. Fix all instances, not just the one found.
2. **Intra-file guard consistency**: If a file has several callbacks of one kind and some have a guard condition but others don't, that is a bug. Either all need the guard or none do.

## Phase 3: Fix Issues

Aggregate findings (wait for any delegated subagents to finish). Fix each real issue directly. Skip false positives without arguing; just note and move on.

## Phase 4: Verify

Find the repo's own verification commands: read the justfile/Makefile, package scripts and CLAUDE.md. Run the verification the repo defines for the packages you touched (typically typecheck, lint, tests, build), and fix failures before generating the description.

Report anything you could not run (missing dependency, environment constraint, credentials, runtime limits) with:
1. what was not run,
2. why,
3. the exact command the human should run.

## Phase 5: Generate PR Description

Produce the description by following the `generate-pr-description` skill (it is the single source of truth for the format). Cover the whole branch (all commits since the base), not just this session. Output it in a fenced code block so the user can copy-paste it directly.
