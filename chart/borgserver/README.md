## Creating host SSH keys without touching the host's disk

```bash
echo '{"apiVersion": "v1", "kind": "Secret", "metadata": { "name": "borgserver-keys-host" }, "data": { "ssh_host_ed25519_key": "'$(mkfifo key && ((cat key | base64 -w0 ; rm key)&) && (echo y | ssh-keygen -N '' -q -t ed25519 -f key > /dev/null))'", "ssh_host_rsa_key": "'$(mkfifo key && ((cat key | base64 -w0 ; rm key)&) && (echo y | ssh-keygen -N '' -q -t rsa -f key > /dev/null))'" }}'
```

You can either pipe it to `kubectl apply` or `kubeseal -o yaml` (if you're using sealed secrets)
