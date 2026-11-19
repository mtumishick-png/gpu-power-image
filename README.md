# GPU Inc Power Image

A powerful GPU cloud image with everything included: SSH, RDP desktop, Cloudflare WARP, Steam/Proton gaming, Sunshine + Parsec streaming, and dev tools.

## What's inside

| Component | Details |
|---|---|
| **Base** | NVIDIA CUDA 12.4.1 (Ubuntu 22.04) |
| **SSH** | OpenSSH server on port 22 (root login) |
| **RDP** | xRDP + XFCE desktop on port 3389 |
| **Network** | Cloudflare WARP client (encrypted DNS + traffic) |
| **Gaming** | Steam + Proton, Sunshine (port 47984-47990), Parsec |
| **Dev** | Python 3, pip, git, vim, tmux, htop |

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `RDP_PASS` | (none) | Root password for SSH + RDP |
| `WARP_MODE` | `on` | `on` = connect WARP, `off` = skip |
| `GAMING` | `false` | `true` = start gaming services |
| `GAMING_MODE` | `sunshine` | `sunshine`, `parsec`, or `both` |

## Build

```bash
docker build -t your-dockerhub-username/gpu-power:latest .
```

## Push to registry

```bash
docker login
docker push your-dockerhub-username/gpu-power:latest
```

## Use on RunPod

In your platform's RunPod creation code, set the image to:
```
your-dockerhub-username/gpu-power:latest
```

And pass env vars:
```json
{
  "RDP_PASS": "your-password",
  "WARP_MODE": "on",
  "GAMING": "true",
  "GAMING_MODE": "sunshine"
}
```

## Ports

| Port | Service |
|---|---|
| 22 | SSH |
| 3389 | RDP |
| 47984-47990 | Sunshine |

## Local test

```bash
docker run --gpus all -p 2222:22 -p 3389:3389 \
  -e RDP_PASS=test123 \
  -e GAMING=false \
  your-dockerhub-username/gpu-power:latest
```

Then connect:
- SSH: `ssh root@localhost -p 2222`
- RDP: `localhost:3389` (user: root, pass: test123)

## Notes

- **WARP in Docker**: If WARP fails to connect, the host's Docker MTU may need to be set to 1420 (see Cloudflare docs).
- **Image size**: ~15-20GB (CUDA + desktop + gaming). RunPod handles this fine.
- **Steam**: First launch requires login. Use `steam` from the desktop or SSH.
- **Proton**: Install via Steam settings → Compatibility → Enable Steam Play for all titles.
