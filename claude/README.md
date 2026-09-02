# claude-tools

A small collection of tools and helpers meant to be used **with [Claude Code](https://claude.com/claude-code)** — scripts that wrap it, sandbox it, or make it easier to run in different environments.

| Tool | What it is |
| --- | --- |
| [`vm-claude`](#vm-claude) | Run Claude Code inside an isolated microVM, one per project |

---

## vm-claude

`vm-claude` runs Claude Code inside a [microsandbox](https://docs.microsandbox.dev) microVM instead of directly on your machine.

The point is isolation: the guest sees **only the current project**, mounted read-write at `/workspace`. Everything else on the host — your home directory, SSH keys, other repos, system files — is simply not there, so a stray `rm -rf` or an over-eager tool call can't reach it.

Because the VM is already the sandbox, `claude` is started with `--dangerously-skip-permissions` by default — no permission prompts inside the box. See [Permissions](#permissions).

Auth, config, and session state live in the VM's own root disk and are keyed per project, so signing in and resuming happen once per project rather than once per run.

### Requirements

- Linux or macOS
- `curl` and `bash`
- The `msb` (microsandbox) CLI — **installed automatically on first run** if it isn't already on your `PATH`

### Install

Drop the script somewhere on your `PATH` and make it executable:

```bash
install -m 755 vm-claude ~/.local/bin/vm-claude
```

### Usage

```bash
vm-claude                 # run claude in a VM for the current project
vm-claude --shell         # drop into a shell in the VM instead of running claude
vm-claude --stop          # stop this project's VM
vm-claude --rm            # stop + delete the VM (wipes its auth/session state)
vm-claude --sign-on-exit  # sign the commits the VM made, on the host, on exit
vm-claude -- <args...>    # pass args straight through to `claude`
```

Examples:

```bash
cd ~/code/my-project
vm-claude                             # first run: boots a VM, installs claude, starts it
vm-claude                             # later runs: resumes the same VM instantly
vm-claude -- --resume                 # forward flags to claude itself
vm-claude -- -p "explain this repo"   # one-shot print mode

cd ~/code/my-project/src/deep/dir
vm-claude                             # same VM as the repo root, but starts in this dir
```

### Permissions

By default `vm-claude` invokes `claude --dangerously-skip-permissions` (with `IS_SANDBOX=1` set inside the guest, which is what allows the flag to be used as root there). The isolation you'd normally get from approving each tool call is already provided by the VM boundary: only the project directory is visible, and everything else in the guest is throwaway.

To get the normal permission prompts back:

```bash
CLAUDE_VM_SKIP_PERMISSIONS=0 vm-claude
```

Note that the flag applies to the *filesystem* only. Claude still has network access from inside the VM (see the caveats below), so treat a `vm-claude` session as unattended-but-online.

### Signing commits

No signing key and no git credentials are ever copied into the guest, so commits made in the VM are unsigned and pushing from inside doesn't work. That's deliberate — but it means a VM session leaves a run of unsigned commits behind.

`--sign-on-exit` closes that gap on the host side:

```bash
vm-claude --sign-on-exit
```

It records `HEAD` before starting the VM and, when the VM exits, signs whatever was committed in the meantime with your host key. When it arms it says so — `sign-on-exit: armed at <sha>` — so an active hook is distinguishable from a flag you forgot to pass. `--shell` sessions are covered too. This works because `/workspace` **is** your host repo — the git root is what's mounted, so commits made in the guest are already real objects in the host's `.git`; only the signature is missing. The hook re-creates them out here, where the key lives:

```bash
git rebase --force-rebase --gpg-sign --autostash <HEAD before the VM ran>
```

`--force-rebase` is the load-bearing flag. A plain `git rebase -S origin/main` onto an ancestor fast-forwards, re-creates no commits, and therefore signs nothing — a quiet no-op that looks like a signing failure.

Set `CLAUDE_VM_SIGN_ON_EXIT=1` to make it the default (`--no-sign-on-exit` turns it off for one run). The hook deliberately does nothing and tells you so when it can't act safely: a detached `HEAD`, no new commits, or a history that diverged from where it started (a rebase or reset inside the VM), since rewriting from the old base would discard work. If the rebase itself fails it runs `git rebase --abort` and prints the command to retry by hand — it never leaves you mid-rebase.

Signing rewrites the commits, so their hashes change. Run it before pushing, not after.

Two things it deliberately cannot do. It only signs commits made **during that run** — anything already unsigned when the VM started sits below the recorded base and stays untouched, so catch those up by hand with `git rebase -f -S <last good commit>`. And the hook lives in the running `vm-claude` process: editing the script, or deciding to enable the flag, does nothing for a session that is already up. A VM started without it will exit without it.

### Timezone

The base image runs UTC, which would stamp every commit made in the VM with a `+0000` offset while your host commits carry the real local one. `vm-claude` installs `tzdata` in the guest and pins its clock to the host's zone — read from `$TZ`, `/etc/timezone`, or the `/etc/localtime` symlink, whichever answers first. Override with `CLAUDE_VM_TZ=Europe/Lisbon`; an unrecognizable value is ignored rather than passed through.

### How it works

1. The mount directory (default `$PWD`) is resolved to an absolute path. If it's inside a git repo, the **repo root** is mounted instead, so `.git` is visible in the guest, and the sub-path is remembered so you land in the equivalent directory under `/workspace`.
2. That path is hashed, producing a stable VM name like `vm-claude-my-project-1234567890`. Each project therefore gets its own persistent VM.
3. **First run** — `msb run` boots the base image with the project mounted at `/workspace`, then inside the guest installs `ca-certificates`, `git`, and `tzdata`, pins the timezone, copies over a safe subset of your host git config (see below), runs `npm install -g @anthropic-ai/claude-code@<version>`, and execs `claude`.
4. **Later runs** — the VM already exists, so it's resumed with `msb exec` and `claude` starts immediately. No reinstall, and you stay logged in.
5. `--stop` shuts the VM down but keeps its disk. `--rm` deletes it, which also destroys the stored credentials and session history for that project.

Because the install happens on first boot, expect the first run in a project to take a minute or two; subsequent runs are fast.

### Git config

So that commits made in the VM aren't authored by `root@<vm>`, the first boot copies an explicit allowlist of `git config --global` values from the host: `user.name`, `user.email`, `init.defaultBranch`, `pull.rebase`, `push.default`, `push.autoSetupRemote`, `rebase.autostash`, `fetch.prune`, `merge.conflictstyle`, `diff.colorMoved`, `color.ui`, and all your `alias.*` entries.

Anything that could carry a secret — `credential.*`, `*.token`, `user.signingkey`, `gpg.*`, `http.*`, `url.*.insteadOf`, `sendemail.*` — is deliberately **not** copied. There are no host credentials in the guest, so pushing from inside the VM won't work out of the box, and commits come out unsigned; see [Signing commits](#signing-commits).

### Configuration

All configuration is via environment variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `CLAUDE_VM_VERSION` | `2.1.235` | npm version of `@anthropic-ai/claude-code` to install |
| `CLAUDE_VM_IMAGE` | `public.ecr.aws/docker/library/node:24-bookworm-slim` | Base OCI image |
| `CLAUDE_VM_CPUS` | `2` | vCPUs |
| `CLAUDE_VM_MEMORY` | `4G` | RAM |
| `CLAUDE_VM_DISK` | `4G` | Root disk size |
| `CLAUDE_VM_MOUNT` | git repo root of `$PWD`, else `$PWD` | Host directory mounted as `/workspace` |
| `CLAUDE_VM_SKIP_PERMISSIONS` | `1` | `1` passes `--dangerously-skip-permissions`; `0` keeps the prompts |
| `CLAUDE_VM_SIGN_ON_EXIT` | `0` | `1` makes `--sign-on-exit` the default |
| `CLAUDE_VM_TZ` | the host's zone | Timezone for the guest, e.g. `Europe/Lisbon` |

```bash
CLAUDE_VM_CPUS=4 CLAUDE_VM_MEMORY=8G vm-claude
CLAUDE_VM_MOUNT=~/code/other-project vm-claude
```

The default image is the AWS ECR public mirror of Docker's official Node image — anonymous pulls, no Docker Hub rate limits or `401`s. Point `CLAUDE_VM_IMAGE` at a Docker Hub tag if you'd rather use that.

Setting `CLAUDE_VM_MOUNT` explicitly also disables the git-root detection: the directory you name is mounted as-is. Since the VM name is derived from that path, a different mount means a different VM with its own state.

### Notes and caveats

- **Sign-in is per project.** Because state lives in the per-project VM disk, the first run in each new project asks you to authenticate again. `--rm` resets that.
- **The VM has network access**, which is what makes `npm install` and the Claude API work. Isolation here is about the filesystem, not the network.
- **Only `/workspace` persists on the host.** Anything Claude writes elsewhere in the guest lives in the VM disk and disappears with `--rm`.
- **Changing `CLAUDE_VM_VERSION` doesn't upgrade an existing VM** — the install only runs on first boot. Use `vm-claude --rm` and start fresh, or upgrade from inside `vm-claude --shell`.
- Upstream docs: <https://docs.microsandbox.dev/examples/agents/claude-code>
