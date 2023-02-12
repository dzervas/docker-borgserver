#!/bin/bash
# Init-Start Script for docker-borgserver

echo "########################################################"
echo " * Containerized BorgServer | Init-Container *"

# Create SSH-Host-Keys on persistent storage, if not exist
echo " * Checking / Preparing SSH Host-Keys..."
for keytype in ed25519 rsa ; do
  if [ ! -f "${SSH_HOST_DIR}/ssh_host_${keytype}_key" ] ; then
    echo "  ** Creating SSH Hostkey [${keytype}]..."
    ssh-keygen -q -f "${SSH_HOST_DIR}/ssh_host_${keytype}_key" -N '' -t ${keytype}
  fi
done

echo

# Gather all SSH-Client-Keys to authorized_keys
echo " * Checking / Preparing SSH Client-Keys..."
for client in $(ls "${SSH_CLIENT_DIR}"); do
  if [ -f "${SSH_CLIENT_DIR}/${client}" ] ; then
    echo "  ** Appending SSH Client key [${client}] to authorized_keys..."
    cat "${SSH_CLIENT_DIR}/${client}" >> "/home/borg/.ssh/authorized_keys"
  fi
done

echo "########################################################"
echo " * Init done! Ready to fire up your borgserver!"

exec "$@"
