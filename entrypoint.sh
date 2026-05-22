#!/bin/sh

# Inject SSH public key if provided via environment variable
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p /home/developer/.ssh
    printf '%s\n' "$SSH_PUBLIC_KEY" > /home/developer/.ssh/authorized_keys
    chmod 700 /home/developer/.ssh
    chmod 600 /home/developer/.ssh/authorized_keys
    chown -R developer:developer /home/developer/.ssh
fi

exec "$@"
