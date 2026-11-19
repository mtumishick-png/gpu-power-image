# ============================================================
# GPU Power Image - Build & Push Script (Windows PowerShell)
# Reads config.env, builds the image, and pushes to registry
# ============================================================

$ErrorActionPreference = "Stop"

# --- Load config.env ---
$config = @{}
Get-Content "$PSScriptRoot\config.env" | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$') {
        $config[$matches[1]] = $matches[2]
    }
}

$registry   = $config['REGISTRY']
$username   = $config['USERNAME']
$imageName  = $config['IMAGE_NAME']
$tag        = $config['TAG']
$fullImage  = "$registry/$username/$imageName`:$tag"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " GPU Power Image - Build and Push" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Registry: $registry"
Write-Host " Image:    $fullImage"
Write-Host "==========================================" -ForegroundColor Cyan

# --- Check Docker ---
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

# --- Check Docker daemon ---
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker daemon is not running. Start Docker Desktop and wait for 'Engine running'." -ForegroundColor Red
    exit 1
}

# --- Build ---
Write-Host ""
Write-Host "[1/2] Building image..." -ForegroundColor Yellow
docker build -t $fullImage "$PSScriptRoot"
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed." -ForegroundColor Red; exit 1 }

# --- Push ---
Write-Host ""
Write-Host "[2/2] Pushing image..." -ForegroundColor Yellow
docker push $fullImage
if ($LASTEXITCODE -ne 0) { Write-Host "Push failed. Did you run 'docker login'?" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Done! Image: $fullImage" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Use this image in RunPod:"
Write-Host "  $fullImage" -ForegroundColor Cyan
Write-Host ""
Write-Host "Env vars to pass:"
Write-Host "  RDP_PASS=$($config['RDP_PASS'])" -ForegroundColor Cyan
Write-Host "  WARP_MODE=$($config['WARP_MODE'])" -ForegroundColor Cyan
Write-Host "  GAMING=$($config['GAMING'])" -ForegroundColor Cyan
Write-Host "  GAMING_MODE=$($config['GAMING_MODE'])" -ForegroundColor Cyan
