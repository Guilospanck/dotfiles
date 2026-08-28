# claude-tools

A small collection of tools and helpers meant to be used **with [Claude Code](https://claude.com/claude-code)** — scripts that wrap it, sandbox it, or make it easier to run in different environments.

| Tool | What it is |
| --- | --- |
| [`claude-vm`](#claude-vm) | Run Claude Code inside an isolated microVM, one per project |

---

## claude-vm

`claude-vm` runs Claude Code inside a [microsandbox](https://docs.microsandbox.dev) microVM instead of directly on your machine.

The point is isolation: the guest sees **only the current project directory**, mounted read-write at `/workspace`. Everything else on the host — your home directory, SSH keys, other repos, system files — is simply not there, so a stray `rm -rf` or an over-eager tool call can't reach it.

Auth, config, and session state live in the VM's own root disk and are keyed per project, so signing in and resuming happen once per project rather than once per run.

### Requirements

- Linux or macOS
- `curl` and `bash`
- The `msb` (microsandbox) CLI — **installed automatically on first run** if it isn't already on your `PATH`

### Install

Drop the script somewhere on your `PATH` and make it executable:

```bash
install -m 755 claude-vm ~/.local/bin/claude-vm
```

### Usage

```bash
claude-vm                 # run claude in a VM for the current directory
claude-vm --shell         # drop into a shell in the VM instead of running claude
claude-vm --stop          # stop this project's VM
claude-vm --rm            # stop + delete the VM (wipes its auth/session state)
claude-vm -- <args...>    # pass args straight through to `claude`
```

Examples:

```bash
cd ~/code/my-project
claude-vm                             # first run: boots a VM, installs claude, starts it
claude-vm                             # later runs: resumes the same VM instantly
claude-vm -- --resume                 # forward flags to claude itself
claude-vm -- -p "explain this repo"   # one-shot print mode
```

### How it works

1. The mount directory (default `$PWD`) is resolved to an absolute path and hashed, producing a stable VM name like `claude-vm-my-project-1234567890`. Each project therefore gets its own persistent VM.
2. **First run** — `msb run` boots the base image with the project mounted at `/workspace`, then inside the guest installs `ca-certificates` and `git`, `npm install -g @anthropic-ai/claude-code@<version>`, and execs `claude`.
3. **Later runs** — the VM already exists, so it's resumed with `msb exec` and `claude` starts immediately. No reinstall, and you stay logged in.
4. `--stop` shuts the VM down but keeps its disk. `--rm` deletes it, which also destroys the stored credentials and session history for that project.

Because the install happens on first boot, expect the first run in a project to take a minute or two; subsequent runs are fast.

### Configuration

All configuration is via environment variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `CLAUDE_VM_VERSION` | `2.1.235` | npm version of `@anthropic-ai/claude-code` to install |
| `CLAUDE_VM_IMAGE` | `public.ecr.aws/docker/library/node:24-bookworm-slim` | Base OCI image |
| `CLAUDE_VM_CPUS` | `2` | vCPUs |
| `CLAUDE_VM_MEMORY` | `4G` | RAM |
| `CLAUDE_VM_DISK` | `4G` | Root disk size |
| `CLAUDE_VM_MOUNT` | `$PWD` | Host directory mounted as `/workspace` |

```bash
CLAUDE_VM_CPUS=4 CLAUDE_VM_MEMORY=8G claude-vm
CLAUDE_VM_MOUNT=~/code/other-project claude-vm
```

The default image is the AWS ECR public mirror of Docker's official Node image — anonymous pulls, no Docker Hub rate limits or `401`s. Point `CLAUDE_VM_IMAGE` at a Docker Hub tag if you'd rather use that.

Changing `CLAUDE_VM_MOUNT` changes the VM name, so a different mount means a different VM with its own state.

### Notes and caveats

- **Sign-in is per project.** Because state lives in the per-project VM disk, the first run in each new project asks you to authenticate again. `--rm` resets that.
- **The VM has network access**, which is what makes `npm install` and the Claude API work. Isolation here is about the filesystem, not the network.
- **Only `/workspace` persists on the host.** Anything Claude writes elsewhere in the guest lives in the VM disk and disappears with `--rm`.
- **Changing `CLAUDE_VM_VERSION` doesn't upgrade an existing VM** — the install only runs on first boot. Use `claude-vm --rm` and start fresh, or upgrade from inside `claude-vm --shell`.
- Upstream docs: <https://docs.microsandbox.dev/examples/agents/claude-code>
