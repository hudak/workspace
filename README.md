# railway-workspace

A generic Railway dev pod template, reusable across projects. Every
project-specific detail — which repo to clone, where to clone it, which SSH
keys to trust, whether to sync dotfiles — is supplied at runtime via
environment variables, so the same image can back quest-logs, mami, or any
future project by creating a new Railway service from this template with
different variable values.

This repo lives on GitHub specifically so Railway's dashboard can use its
native GitHub auto-deploy — no manual docker build/push loop.

## Access model

SSH is the only standing listener. VS Code Desktop connects via Remote-SSH.
If a browser-based VS Code session is ever needed, it's started manually over
an already-authenticated SSH session (`code tunnel --accept-server-license-terms`)
and closed when done — there is no automatically-started web listener.

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `AUTHORIZED_KEYS` | Yes | SSH public key(s) allowed to connect |
| `GIT_CLONE_URL` | No | Full clone URL for the project repo, credentials embedded if needed (e.g. `https://oauth2:<token>@gitlab.com/user/repo.git`) |
| `WORKSPACE_DIR` | No, but required if `GIT_CLONE_URL` is set | Subdirectory name under `/workspace/projects` to clone into |
| `DOTFILES_REPO` | No | yadm-managed dotfiles repo URL. The dotfiles repo is private, so this must include an embedded token, e.g. `https://<token>@github.com/hudak/dotfiles.git` — same credential-embedding pattern as `GIT_CLONE_URL` |

`GIT_CLONE_URL` and `DOTFILES_REPO` are independent — a pod can have either,
both, or neither.

The token embedded in `DOTFILES_REPO` should be a GitHub fine-grained PAT
scoped to read-only Contents access on just the dotfiles repo, not a classic
token with broader repo access.

## Deployment

Railway dashboard → New Project → Deploy from GitHub repo → select this repo.
One Railway service + one volume mounted at `/workspace` per project, each
with its own variable values.

## Networking

A TCP Proxy on port 22 is required for both SSH access and for the
Serverless/scale-to-zero wake trigger to work (an inbound TCP connection is
what Railway's edge watches for to wake a sleeping service).

## Volume layout

Everything durable lives under the single `/workspace` mount:

- `/workspace/home` — dev's `$HOME`, including yadm-managed dotfiles, shell
  history, and `code tunnel`'s own state (auth, cached extensions)
- `/workspace/projects/<WORKSPACE_DIR>` — the cloned project repo
- `/workspace/.ssh-hostkeys` — persisted sshd host keys

## Browser-based VS Code on demand

`ssh` in, then run:

```
code tunnel --accept-server-license-terms
```

and stop it with `Ctrl+C` when done.

## Dotfiles bootstrap is manual

`yadm clone` runs automatically, but only once ever per volume — the first
time `$HOME` (now durable) doesn't already have a yadm repo in it.
`yadm bootstrap` never runs automatically, since it may prompt interactively
(e.g. for a sudo password). After the first connection, run it yourself;
after any later `yadm pull`, run it again.

None of the environment variable values are ever committed to this repo.
