# Script de deploy manual a Firebase Hosting
# Uso: .\deploy.ps1
# Las credenciales se leen de variables de entorno o del archivo .vscode\launch.json

param(
    [string]$SupabaseUrl     = $env:SUPABASE_URL,
    [string]$SupabaseAnon    = $env:SUPABASE_ANON,
    [string]$VapidPublicKey  = $env:VAPID_PUBLIC_KEY
)

if (-not $SupabaseUrl -or -not $SupabaseAnon) {
    Write-Error "Faltan credenciales. Seteá SUPABASE_URL y SUPABASE_ANON como variables de entorno o pasalas como parámetros."
    exit 1
}

Write-Host "Construyendo Flutter web..." -ForegroundColor Cyan

$buildArgs = @(
    "build", "web", "--release",
    "--dart-define=SUPABASE_URL=$SupabaseUrl",
    "--dart-define=SUPABASE_ANON=$SupabaseAnon"
)
if ($VapidPublicKey) {
    $buildArgs += "--dart-define=VAPID_PUBLIC_KEY=$VapidPublicKey"
}

puro flutter @buildArgs
if ($LASTEXITCODE -ne 0) { Write-Error "Build fallido."; exit 1 }

Write-Host "Generando version.json..." -ForegroundColor Cyan
$Version = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
Set-Content -Path "build\web\version.json" -Value "{ `"version`": `"$Version`" }"

Write-Host "Desplegando a Firebase..." -ForegroundColor Cyan
firebase deploy --only hosting
