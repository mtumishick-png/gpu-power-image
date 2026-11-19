#!/bin/bash
# ============================================================
# GPU Inc Power Image — Entrypoint
# Runs on every container boot. Configures SSH, RDP, WARP,
# and starts gaming services based on env vars.
# ============================================================
set -e

echo "=========================================="
echo " GPU Inc Power Image — Starting"
echo "=========================================="

# --- 1. Set root password from env ---
if [ -n "$RDP_PASS" ]; then
    echo "root:$RDP_PASS" | chpasswd
    echo "[1/6] Root password set from RDP_PASS"
else
    echo "[1/6] WARNING: RDP_PASS not set — root password unchanged"
fi

# --- 2. Start SSH ---
mkdir -p /var/run/sshd
/usr/sbin/sshd
echo "[2/6] SSH started on port 22"

# --- 3. Start xRDP ---
service xrdp start || /usr/sbin/xrdp
echo "[3/6] xRDP started on port 3389"

# --- 4. Cloudflare WARP ---
if [ "$WARP_MODE" != "off" ]; then
    echo "[4/6] Connecting Cloudflare WARP..."
    warp-cli --accept-tos registration new 2>/dev/null || true
    warp-cli --accept-tos connect 2>/dev/null || true
    sleep 2
    STATUS=$(warp-cli --accept-tos status 2>/dev/null || echo "unknown")
    echo "[4/6] WARP status: $STATUS"
else
    echo "[4/6] WARP disabled (WARP_MODE=off)"
fi

# --- 5. Gaming services ---
if [ "$GAMING" = "true" ]; then
    echo "[5/6] Starting gaming services..."
    if [ "$GAMING_MODE" = "parsec" ] || [ "$GAMING_MODE" = "both" ]; then
        parsec 2>/dev/null &
        echo "[5/6] Parsec started"
    fi
    if [ "$GAMING_MODE" = "sunshine" ] || [ "$GAMING_MODE" = "both" ] || [ -z "$GAMING_MODE" ]; then
        sunshine 2>/dev/null &
        echo "[5/6] Sunshine started"
    fi
else
    echo "[5/6] Gaming disabled (GAMING != true)"
fi

# --- 6. Keep container alive ---
echo "[6/6] Container ready. SSH:22 RDP:3389"
echo "=========================================="
tail -f /dev/null
