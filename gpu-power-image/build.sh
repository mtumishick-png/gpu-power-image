#!/bin/bash
# ============================================================
# GPU Power Image — Build & Push Script (Linux/Mac)
# Reads config.env, builds the image, and pushes to registry
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Load config.env ---
set -a
source "$SCRIPT_DIR/config.env"
set +a

FULL_IMAGE="$REGISTRY/$USERNAME/$IMAGE_NAME:$TAG"

echo "=========================================="
echo " GPU Power Image — Build & Push"
echo "=========================================="
echo " Registry: $REGISTRY"
echo " Image:    $FULL_IMAGE"
echo "=========================================="

# --- Check Docker ---
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed."
    exit 1
fi

# --- Build ---
echo ""
echo "[1/2] Building image..."
docker build -t "$FULL_IMAGE" "$SCRIPT_DIR"

# --- Push ---
echo ""
echo "[2/2] Pushing image..."
docker push "$FULL_IMAGE"

echo ""
echo "=========================================="
echo " Done! Image: $FULL_IMAGE"
echo "=========================================="
echo ""
echo "Use this image in RunPod:"
echo "  $FULL_IMAGE"
echo ""
echo "Env vars to pass:"
echo "  RDP_PASS=$RDP_PASS"
echo "  WARP_MODE=$WARP_MODE"
echo "  GAMING=$GAMING"
echo "  GAMING_MODE=$GAMING_MODE"
