# Dev Environment Docker Container

A Debian-based development environment container with SSH access, Zsh shell, and Docker CLI support.

## Features

- SSH access with key-based authentication
- Zsh as the default shell
- Docker CLI (connects to host Docker via socket mount)
- Non-root `developer` user with sudo access
- GitHub Actions CI for building and pushing to GHCR

## Quick Start

### Build and run with docker-compose

```bash
docker compose up -d --build
```

### SSH into the container

```bash
ssh -p 2222 developer@localhost
```

## SSH Authentication

### Option 1: Build-time key injection

```bash
docker build --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" -t dev-env .
```

### Option 2: Runtime mount

Copy your public key into an `authorized_keys` file and mount it:

```bash
mkdir -p ~/.ssh-dev
cp ~/.ssh/id_ed25519.pub ~/.ssh-dev/authorized_keys
```

Then add to `docker-compose.yml`:

```yaml
volumes:
  - ~/.ssh-dev/authorized_keys:/home/developer/.ssh/authorized_keys:ro
```

### Option 3: Manual copy (after container is running)

```bash
docker compose exec dev mkdir -p /home/developer/.ssh
cat ~/.ssh/id_ed25519.pub | docker compose exec -T tee /home/developer/.ssh/authorized_keys
docker compose exec dev chmod 600 /home/developer/.ssh/authorized_keys
docker compose exec dev chown developer:developer /home/developer/.ssh/authorized_keys
```

## Without docker-compose

### Build

```bash
docker build --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" -t dev-env .
```

### Run

```bash
docker run -d \
  --name dev-env \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  dev-env
```

## GitHub Actions

The workflow at `.github/workflows/ci.yml` builds and pushes the image to GHCR on every push to `main`.

The image will be available at:
```
ghcr.io/<owner>/<repo>:latest
ghcr.io/<owner>/<repo>:sha-<commit-sha>
```

## Docker Socket

The Docker socket is mounted from the host, giving the container access to the host's Docker daemon. This allows you to run Docker commands from inside the container.

> **Note**: The Docker socket mount has security implications. The `developer` user inside the container effectively has root access on the host via Docker. Only use this in trusted environments.
