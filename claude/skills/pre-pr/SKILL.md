---
name: pre-pr
description: Use when ready to open a PR, before committing final changes. Reviews changed code for dead code, stale docs/comments, code quality, efficiency, and security issues, fixes them, then generates a copy-paste PR description.
---

# Pre-PR Review and Description

Final cleanup pass on all changed files before opening a PR. Finds and fixes issues, then produces a ready-to-paste PR description.

## Phase 1: Identify Changes

Run `git diff` (or `git diff HEAD` if there are staged changes) to see what changed. If there are no git changes, review the most recently modified files from the conversation.

Also run `git log main..HEAD --oneline` (or equivalent base branch) to understand the full commit history for the PR description.

## Phase 2: Launch Six Review Agents in Parallel

Use the Agent tool to launch all six agents concurrently. Pass each agent the full diff.

### Agent 1: Dead Code and Stale Docs

For each changed file:

1. **Find dead code**: unused fields, unreachable branches, unused imports, unused variables, functions only called from deleted code, enum/type union variants never referenced. Also check for **orphaned UI state/DOM** — if a feature that used state (markers, timers, DOM elements) was removed, verify the state creation and cleanup code was also removed.
2. **Find stale comments and docs**: JSDoc that no longer matches the function signature or behavior, TODO/FIXME for things already done, comments describing code that was changed or removed, outdated parameter descriptions. Also check **inline comments that describe mechanism** (e.g., "limits concurrent processes") — verify the comment accurately describes what the code actually does.
3. **Find stale re-exports**: barrel files (`index.ts`) exporting removed or renamed symbols. Also check for **incomplete re-exports** — when new public functions are added to a module, verify they are re-exported from the parent barrel file if that barrel already re-exports siblings from the same module.

### Agent 2: Code Reuse

For each change:

1. **Search for existing utilities and helpers** that could replace newly written code. Use Grep to find similar patterns elsewhere in the codebase.
2. **Flag any new function that duplicates existing functionality.**
3. **Flag inline logic that could use an existing utility** (hand-rolled string manipulation, manual path handling, ad-hoc type guards, etc.).

### Agent 3: Code Quality

Review the changes for hacky patterns:

1. **Redundant state**: state that duplicates existing state, cached values that could be derived (e.g. a boolean field that is always `!otherField`).
2. **Duplicate types**: identical type definitions that should be merged.
3. **Copy-paste with slight variation**: near-duplicate code blocks that should share an abstraction.
4. **Stringly-typed code**: raw strings where constants, enums, or branded types already exist.
5. **Unmatched paired events**: every "open" must have a guaranteed "close" — e.g., mousedown without guaranteed mouseup (user releases outside element), subscribe without unsubscribe, lock without unlock on all paths. Check that cleanup/release handlers fire even in edge cases (blur, disconnect, element removal). Specifically: if `initialize()` calls `addEventListener`, then `cleanup()` MUST call `removeEventListener` for every listener added — otherwise re-initialization after cleanup attaches duplicate handlers.
6. **Unfiltered event handlers**: event handlers that don't filter to the intended trigger — e.g., mousedown handling all buttons when only left-click is intended (`event.button !== 0`), keydown not checking for repeat, etc.
7. **String comparison without normalization**: comparing user input or event values (e.g., `event.key`) without case normalization when the value can vary in case.
8. **Ignored return values**: functions that return success/failure booleans or errors whose return value is discarded by the caller, especially when the caller then logs "success" unconditionally.
9. **Module-level mutable state shared across instances**: mutable variables at module/package scope (e.g., `let lastTime = 0`) that are implicitly shared across all callers/instances. Should be scoped per instance (closure, WeakMap, per-object field) unless sharing is intentional.
10. **Side effects before validation**: calling `event.preventDefault()`, mutating state, updating throttle/debounce timestamps, or sending messages before confirming the operation will succeed (e.g., validation passes, channel is open, coordinates are valid). Side effects should happen after the point of no return, not before. A throttle timestamp updated before a null-check suppresses the next valid event.
11. **Off-by-one in numeric conversions**: when converting between ranges (e.g., normalized 0.0–1.0 to pixel 0–1919), check boundary values. `int(1.0 * 1920) == 1920` is out of bounds. Clamp to `[0, max-1]`.
12. **Cross-language type/size mismatches**: when the same value crosses a language boundary (e.g., TS → JSON → Go), verify that size checks use the same semantics. JS `string.length` counts UTF-16 code units; Go `len(string)` counts UTF-8 bytes. Use `TextEncoder` for byte-accurate length in JS.
13. **Backward compatibility when removing protocol messages**: if a message type is removed from the sender, check whether older peers might still send it. Either keep handling it on the receiver (with a deprecation comment) or confirm no backward-compat risk.
14. **State tracking after failed/dropped operations**: if an operation is tracked in state (e.g., added to a map) before an external call, and the call fails or is dropped (rate-limited, timeout), the state must be rolled back. Otherwise tracked state drifts from actual state (e.g., key tracked as "held" but never actually pressed).
15. **Race between unlock-call-relock patterns**: when releasing a lock to perform an external call, then re-acquiring to update state, another goroutine can modify the state in between. Prefer: track optimistically under lock first, perform the call, then roll back under lock on failure — this way concurrent operations see consistent state.
16. **Global event handlers that intercept local UI**: window-level event handlers (paste, keydown, etc.) that intercept events meant for local editable elements (inputs, textareas, contenteditable). Must check `isEditableEventTarget(event.target)` before intercepting, same guard used for keyboard events.
18. **Concurrent writes to shared output**: when multiple goroutines/callbacks can invoke the same output operation (e.g., `xdotool type`, serial port write, file append) concurrently, the outputs will interleave. Serialize with a mutex or queue.
19. **Parameter accepted but not used to control behavior**: a function accepts a parameter (e.g., a mode/type enum) but the code path it's supposed to control is driven by a different value (e.g., presence of another argument). The parameter becomes meaningless and callers get wrong behavior when the two disagree.
20. **Resource-acquiring class without cleanup API**: a class that starts long-lived operations (timers, event listeners, recognition sessions) in a method like `start()` but exposes no `stop()`/`dispose()`/`close()` to let callers release those resources. Callers have no way to clean up, causing leaks.
21. **Aggregator replacement drops upstream event fan-in**: in any room/session-level aggregator that replaces per-peer/per-source channel instances, replacement logic can accidentally unsubscribe listeners from an older still-active sibling source. During reconnection/recovery/duplication windows, payloads may continue on the old source; if listener fan-in was removed, transport-level logs still appear but feature-level handlers silently stop receiving events. Require replacement-safe fan-in and add a regression test that emits from the pre-replacement source after replacement.
22. **Derived UI state ignores authoritative lifecycle source**: UI/control state is derived from one layer (for example, per-peer senders/channels) while another authoritative layer (for example, room-level local track/media capture/session state) also controls whether the feature is active. This causes enabled/disabled controls and status text to drift from actual runtime behavior. Derive state from all authoritative sources and add a regression test for the empty/zero-peer case.
23. **Validation happens after resource creation**: if label/type/id/path validation happens only in registration or downstream handlers, constructors/factories may already allocate unmanaged resources before rejection. Validate identifiers before creating channels/files/sessions so invalid inputs fail fast without orphaning objects.
17. **Out-of-bounds coordinates from fallback/edge-case paths**: when a function has multiple code paths (e.g., object-fit aware vs fallback), ensure ALL paths clamp or validate output ranges consistently. A fallback path that skips validation can produce out-of-range values when triggered from edge cases (e.g., mouseup outside element via window listener).
24. **Constructor field assignment after method call**: in a constructor, if a method is called (especially async) before a field is assigned, the method may use the field synchronously before it's set. Async methods execute synchronously until their first `await` — so `this._promise = this._asyncMethod(); this._field = value;` means `_asyncMethod` sees `_field` as `undefined` if it uses it before its first `await`. All fields must be assigned BEFORE any method calls in the constructor.
25. **Write-path identifier change without updating read-path comparisons**: when a new branch introduces an alternative identifier (label/key/path) into the *write* side of a function (e.g., a stored `transcriptLabel`, cache key, map entry), verify every earlier *read* site in the same function — dedup checks, lookups, early returns, comparisons — also respects the new identifier. Otherwise subsequent calls with the same inputs won't match the original write and logic will re-run (stop/restart loops, duplicate work, repeated allocations). The "same inputs produce same identifier" invariant must hold across both write and read paths.
26. **Validator builds Map without guarding against duplicate keys**: when a validator constructs a `Map<key, value>` by iterating over a user-supplied collection (e.g., channel lists, rule arrays) and calling `map.set(key, value)`, duplicate keys silently overwrite earlier entries. This can make downstream validation (existence checks, type checks, cycle detection) behave on the *last* duplicate only, accepting ambiguous or conflicting configs. Reject duplicate keys explicitly with a descriptive error before the `set`, or use a structure that enforces uniqueness up-front.
27. **Exact-equality check on an identifier that now has multiple valid formats**: when a new PR introduces a new protocol / MIME / URL / key format alongside an existing one (e.g., adds `text/plain;...;subtype=transcript` alongside `text/transcript`), grep for `=== "<old-literal>"` and `!== "<old-literal>"` on that identifier across the codebase. Downstream guards checking exact equality will silently reject the new variant and the surrounding code path (TTS wiring, message routing, subscription setup) will no-op without error. Replace the equality check with a predicate helper (e.g., `isTranscriptProtocol(p)`) or a constant set membership check, and add a test that exercises each valid format.
28. **Tests that stub the function under test mask regressions**: a unit test asserting that feature X wires up component Y must NOT stub the function that performs the wiring. Stubbing the subject means the test passes on the *stub's* behavior, not production behavior — if an early-return guard, protocol check, or permission check inside the real function ever rejects the test fixture's data, the test will still pass. Limit stubbing to external dependencies (browser APIs, network, I/O, rate limiters, speech engines). For the unit under test, pass in realistic fixtures whose shapes match what real producers emit (e.g., config DC protocols must match what `_autoCreateChannelsForPeer` produces, not a convenient simplification) and assert on observable side-effects (event subscriptions added, callbacks invoked, state written).

### Agent 4: Efficiency

Review the changes for waste:

1. **Redundant calls**: the same function called multiple times when once suffices (e.g. `updateUI()` called in both caller and callee).
2. **Unnecessary work**: redundant computations, duplicate network calls, N+1 patterns.
3. **Memory leaks**: unbounded data structures, missing cleanup, event listener leaks.
4. **Locks held during I/O or external calls**: mutexes/locks held while calling slow operations (network, subprocess, file I/O). Collect state under the lock, release it, then perform the slow work outside the critical section.
5. **Late validation**: if a size/format limit is enforced deep in the call chain (e.g., `InjectType` rejects >64KB), check whether the parser that creates the data also enforces the limit. Rejecting early at the parser avoids allocating and passing around data that will be rejected later.
6. **Synchronous blocking in event callbacks**: long-running synchronous operations (subprocess calls, network I/O) inside event callbacks (data channel onMessage, WebSocket handlers) block the entire callback pipeline. Offload to a goroutine or worker queue so the handler stays responsive.
7. **Unbounded concurrent subprocess spawning**: fire-and-forget process creation (`cmd.Start()` + goroutine `cmd.Wait()`) without a concurrency cap can exhaust the process table if the subprocess hangs or slows down. Add an in-flight semaphore alongside any rate limiter. The rate limiter caps creation rate; the semaphore caps concurrent count.
8. **Duplicate event emission across layers**: when a low-level method (e.g., `createDataChannel`) emits an event, and the higher-level caller also emits the same event for the same object, listeners receive duplicates. Only one layer should emit — typically the layer closest to the consumer.

### Agent 5: Security

Review the changes for security vulnerabilities (OWASP top 10 and WebRTC-specific):

1. **Injection**: HTML injection via `innerHTML` with untrusted data (user input, peer IDs, room names). Use `textContent` or DOM APIs instead.
2. **Input validation at boundaries**: untrusted data from signaling messages, peer connections, or user input used without validation or sanitization.
3. **Sensitive data exposure**: credentials, tokens, API keys, or secrets hardcoded or logged. Check `.env` files aren't committed. Also check for **user-controlled content logged verbatim** (clipboard text, message bodies, file contents) — log metadata (length, type) instead of content.
4. **Defense-in-depth validation**: if a size/format limit is enforced on one side (e.g., server), check that the same limit is also enforced on the sending side to avoid wasting bandwidth and to fail fast.
5. **Prototype pollution / unsafe object access**: unchecked property access on objects from external sources (e.g., parsed JSON from signaling).
6. **Resource exhaustion**: unbounded allocations triggered by remote peers (e.g., creating unlimited channels, sending unlimited messages).
7. **Missing origin/permission checks**: WebRTC-specific — ensure ICE candidates and SDP offers are only processed from known peers.
8. **Insecure defaults**: missing HTTPS/WSS enforcement, permissive CORS, disabled security headers.
9. **Non-standard APIs without error handling**: browser APIs that may throw or be unsupported (e.g., `jitterBufferTarget`, `getDisplayMedia` constraints) must be wrapped in try/catch. Non-standard property access should degrade gracefully.
10. **Protocol/MIME naming drift**: when a protocol identifier or MIME type (e.g., `screenshare.pointer+json`) no longer accurately describes what it carries (now also keyboard, clipboard), flag the mismatch. Renaming is a breaking change — at minimum update docs/comments.

### Agent 6: Documentation Staleness

Validate that project documentation (README.md, ARCHITECTURE.md, and any other .md files in the repo — excluding CLAUDE.md, AGENTS.md, and skill files) is consistent with the current codebase. For each changed file in the diff:

1. **API signature drift**: If a public function/method/class was added, removed, renamed, or had its signature changed, check whether any README or doc file references it. Flag docs that show the old signature, wrong parameter types, or missing new APIs.
2. **Async/sync mismatch in examples**: If a function's return type changed (e.g., from `Promise<T>` to `T` or vice versa), check that code examples in docs use/omit `await` correctly.
3. **New exports not documented**: If `index.ts` or a barrel file gained new exports, check whether the relevant README lists them. Flag undocumented public API surface.
4. **Removed features still documented**: If code was deleted (files, classes, functions), check whether docs still reference them. Flag phantom documentation for things that no longer exist.
5. **Architecture diagrams out of date**: If the layer structure changed (new channel types, new modules, new control messages), check whether ARCHITECTURE.md or README architecture sections reflect the change.
6. **Project structure trees**: If files/directories were added or removed, check whether any project structure tree in docs matches the actual filesystem.
7. **Dependency/tooling claims**: If dependencies changed (package.json, go.mod), check whether docs still claim correct dependencies. Flag docs that reference removed libraries or miss newly added ones.
8. **Stale companion/tool docs**: For changes to companion services (companions/), check that their individual READMEs match the current Docker images, CLI commands, environment variables, and architecture.

For each finding, report the doc file path, the specific section, and what's wrong. Include a suggested fix.

### Cross-cutting: Sibling Consistency

After each agent reports findings, apply these two mandatory cross-checks before fixing:

1. **Sibling file check**: For every issue found in a file, search for sibling files that follow the same pattern (e.g., other handler implementations, other channel types, other modules with the same interface). If the issue exists in the changed file, it very likely exists in its siblings too. Fix all instances, not just the one the agent found.
2. **Intra-file guard consistency**: If a file has multiple event callbacks (e.g., `channelOpen`, `trackStateChanged`, `channelClose`) and some have a guard condition (e.g., `if (currentLabel === label)`) but others don't, that's a bug — either all need the guard or none do. Check every callback group for missing guards.

## Phase 3: Fix Issues

Wait for all six agents to complete. Aggregate findings. Fix each real issue directly. Skip false positives without arguing — just note and move on.

## Phase 4: Verify

Run the **full available verification matrix** for every touched package/module. Everything must pass before generating the PR description.

Minimum expectation (where available):
- typecheck
- lint/static checks
- unit tests
- integration tests
- end-to-end tests
- build/package checks

**Required commands** (run from the repo root):
- `just typecheck-all` — runs typecheck across all packages (uses stricter tsconfig that includes test files)
- `just lib-build` — rebuild the library dist/ before e2e tests (dashboard imports compiled dist/, not src/)
- `just test-all` — runs all tests (library + dashboard unit + dashboard e2e)

Do not stop at a subset just because some commands pass. If a verification class exists in the repo and is relevant to changed code, run it.

If any verification class cannot be run (missing dependency, environment constraint, credentials, runtime limits), explicitly report:
1. what was not run,
2. why,
3. the exact command the human should run.

## Phase 5: Generate PR Description

Run `git diff main..HEAD` and `git log main..HEAD --oneline` to capture all changes across the branch (not just this session). Produce a **short, high-level** PR description. Do NOT list individual files or line-level changes — summarize what changed and why at the feature/behavior level.

```
## Summary
<3-5 short bullet points: what changed and why, at the feature level>

## Testing
<one-liner: what was verified>
```

Output the description in a fenced code block so the user can copy-paste it directly.
