# Dev Environment Docker Container

A Debian-based development environment container with SSH access, Zsh shell, and Docker CLI support.

## Features

- SSH access with key-based authentication
- Zsh as the default shell
- Docker CLI (connects to host Docker via socket mount)
- Non-root `developer` user with sudo access
- GitHub Actions CI for building and pushing to GHCR
- Configurable via environment variables

## Quick Start

### Run with docker-compose

Set your image and pull:

```bash
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" docker compose up -d
```

### SSH into the container

```bash
ssh -p 2222 developer@localhost
```

## Configuration

Override defaults by creating a `.env` file or exporting environment variables before running `docker compose`:

| Variable | Default | Description |
| --- | --- | --- |
| `CONTAINER_NAME` | `dev-env` | Container name |
| `IMAGE_NAME` | `ghcr.io/OWNER/REPO:stable` | Image to pull |
| `SSH_PORT` | `2222` | Host port for SSH |
| `TIMEZONE` | `UTC` | Container timezone |
| `SSH_PUBLIC_KEY` | *(empty)* | SSH public key for authentication |

Example `.env`:

```env
CONTAINER_NAME=my-dev
IMAGE_NAME=ghcr.io/myorg/my-dev:stable
SSH_PORT=2200
TIMEZONE=America/New_York
SSH_PUBLIC_KEY=ssh-ed25519 AAAA... your@email.com
```

## Without docker-compose

```bash
docker run -d \
  --name dev-env \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ghcr.io/OWNER/REPO:stable
```

## GitHub Actions

The workflow at `.github/workflows/ci.yml` builds and pushes the image to GHCR on every push to `main`.

The image will be available at:
```
ghcr.io/<owner>/<repo>:stable
ghcr.io/<owner>/<repo>:sha-<commit-sha>
```

## Docker Socket

The Docker socket is mounted from the host, giving the container access to the host's Docker daemon. This allows you to run Docker commands from inside the container.

> **Note**: The Docker socket mount has security implications. The `developer` user inside the container effectively has root access on the host via Docker. Only use this in trusted environments.
