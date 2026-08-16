#!/bin/bash
set -e

DEV_HOME=/workspace/home
PROJECTS_DIR=/workspace/projects

# Move dev's home directory onto the persistent volume, seeding it with
# skeleton files the first time it's created. This makes $HOME durable
# across sleep/wake — the reason dotfiles bootstrap only has to run once
# per volume's lifetime, not once per wake.
if [ ! -d "$DEV_HOME" ]; then
  mkdir -p "$DEV_HOME"
  cp -a /etc/skel/. "$DEV_HOME/"
fi
usermod -d "$DEV_HOME" dev
chown -R dev:dev "$DEV_HOME"

# Persist SSH host keys across sleep/wake and redeploys — without this,
# every wake looks like a new host to your ssh client
if [ ! -f /workspace/.ssh-hostkeys/ssh_host_rsa_key ]; then
  mkdir -p /workspace/.ssh-hostkeys
  ssh-keygen -A
  cp /etc/ssh/ssh_host_*_key* /workspace/.ssh-hostkeys/
else
  cp /workspace/.ssh-hostkeys/ssh_host_*_key* /etc/ssh/
fi

# Authorize key(s) from the Railway env var on every boot
mkdir -p "$DEV_HOME/.ssh"
echo "$AUTHORIZED_KEYS" > "$DEV_HOME/.ssh/authorized_keys"
chmod 700 "$DEV_HOME/.ssh"
chmod 600 "$DEV_HOME/.ssh/authorized_keys"
chown -R dev:dev "$DEV_HOME/.ssh"

# Sync dotfiles via yadm — only on the very first boot for this volume,
# since $HOME now persists. After that, pull updates and bootstrap manually:
#   yadm pull && yadm bootstrap
if [ -n "$DOTFILES_REPO" ] && [ ! -d "$DEV_HOME/.local/share/yadm/repo.git" ]; then
  su - dev -c "yadm clone '${DOTFILES_REPO}' --force"
fi

# Clone the project into the persistent volume — only if it isn't there already
mkdir -p "$PROJECTS_DIR"
if [ -n "$GIT_CLONE_URL" ] && [ ! -d "${PROJECTS_DIR}/${WORKSPACE_DIR}" ]; then
  git clone "${GIT_CLONE_URL}" "${PROJECTS_DIR}/${WORKSPACE_DIR}"
  chown -R dev:dev "${PROJECTS_DIR}/${WORKSPACE_DIR}"
fi

exec /usr/sbin/sshd -D -e
