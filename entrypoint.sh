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
service dbus start 2>/dev/null || dbus-daemon --system --fork 2>/dev/null || true
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
# --- noVNC ---
if [ "$NOVNC_MODE" = "on" ]; then
    echo "[noVNC] Starting virtual display :1..."
    Xvfb :1 -screen 0 1360x768x24 &
    sleep 2
    DISPLAY=:1 startxfce4 &
    sleep 2
    x11vnc -display :1 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 &
    websockify --web /usr/share/novnc 6080 localhost:5900 &
    echo "[noVNC] Ready at http://<pod-ip>:6080/vnc.html"
fi
# --- 6. Safety brakes: auto-stop on idle or max runtime ---
MAX_RUNTIME_HOURS=${MAX_RUNTIME_HOURS:-4}
IDLE_TIMEOUT_MIN=${IDLE_TIMEOUT_MIN:-15}
START_TIME=$(date +%s)
IDLE_COUNT=0
echo "[6/6] Safety brakes: max ${MAX_RUNTIME_HOURS}h, idle ${IDLE_TIMEOUT_MIN}min"
while true; do
    sleep 60
    NOW=$(date +%s)
    RUNTIME_MIN=$(( (NOW - START_TIME) / 60 ))
    if [ $RUNTIME_MIN -ge $((MAX_RUNTIME_HOURS * 60)) ]; then
        echo "[SAFETY] Max runtime ${MAX_RUNTIME_HOURS}h reached. Stopping pod."
        exit 0
    fi
    CONNS=$(ss -tn state established 2>/dev/null | grep -E ':22 |:3389 ' | wc -l)
    LOAD=$(awk '{print $1}' /proc/loadavg)
    LOW=$(awk -v l=$LOAD 'BEGIN{print (l<0.2)?1:0}')
    if [ "$CONNS" -lt 1 ] && [ "$LOW" = "1" ]; then
        IDLE_COUNT=$((IDLE_COUNT + 1))
    else
        IDLE_COUNT=0
    fi
    if [ $IDLE_COUNT -ge $IDLE_TIMEOUT_MIN ]; then
        echo "[SAFETY] Idle for ${IDLE_TIMEOUT_MIN}min. Stopping pod."
        exit 0
    fi
done
