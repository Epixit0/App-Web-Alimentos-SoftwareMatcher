param(
  [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path,
  [string]$Configuration = "Release",
  [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"

$payloadRoot = Join-Path $RepoRoot "installer\dist\payload"
$payloadApp = Join-Path $payloadRoot "app"
$payloadService = Join-Path $payloadRoot "service"

Write-Host "Staging payload -> $payloadRoot" -ForegroundColor Cyan

# Clean
if (Test-Path $payloadRoot) { Remove-Item -Recurse -Force $payloadRoot }
New-Item -ItemType Directory -Force -Path $payloadApp | Out-Null
New-Item -ItemType Directory -Force -Path $payloadService | Out-Null

# 1) dotnet publish -> payload\app
$csproj = Join-Path $RepoRoot "MatcherApi.csproj"
if (!(Test-Path $csproj)) { throw "No existe csproj en: $csproj" }

Write-Host "Publishing .NET -> $payloadApp (runtime=$Runtime)" -ForegroundColor Cyan

# Self-contained single-file
# PublishTrimmed=false por seguridad.
dotnet publish $csproj `
  -c $Configuration `
  -r $Runtime `
  --self-contained true `
  -o $payloadApp `
  /p:PublishSingleFile=true `
  /p:IncludeNativeLibrariesForSelfExtract=true `
  /p:PublishTrimmed=false

if ($LASTEXITCODE -ne 0) {
  throw "dotnet publish falló (exit=$LASTEXITCODE)"
}

$matcherExe = Join-Path $payloadApp "MatcherApi.exe"
if (!(Test-Path $matcherExe)) {
  throw "Staging incompleto: no quedó MatcherApi.exe en $payloadApp"
}

# 2) WinSW wrapper + XML
$winswExe = Join-Path $RepoRoot "installer\assets\winsw\MarCaribeSoftwareMatcher.exe"
$winswXml = Join-Path $RepoRoot "installer\assets\winsw\MarCaribeSoftwareMatcher.xml"

if (!(Test-Path $winswXml)) {
  throw "Falta XML WinSW en: $winswXml"
}

if (!(Test-Path $winswExe)) {
  # Si estás en el monorepo, intenta reusar el WinSW del Agent
  $agentWinSw = Join-Path $RepoRoot "..\App-Web-Alimentos-Agent\installer\assets\winsw\MarCaribeFingerprintAgent.exe"
  if (Test-Path $agentWinSw) {
    Copy-Item -Force -LiteralPath $agentWinSw -Destination $winswExe
    Write-Host "OK: copiado WinSW desde Agent -> $winswExe" -ForegroundColor Green
  }
}

if (!(Test-Path $winswExe)) {
  throw "Falta WinSW exe en: $winswExe. Copia el wrapper (WinSW) ahí y vuelve a correr stage.ps1."
}

Copy-Item -Force -LiteralPath $winswExe -Destination $payloadService
Copy-Item -Force -LiteralPath $winswXml -Destination $payloadService

$payloadWinSWExe = Join-Path $payloadService "MarCaribeSoftwareMatcher.exe"
$payloadWinSWXml = Join-Path $payloadService "MarCaribeSoftwareMatcher.xml"
if (!(Test-Path $payloadWinSWExe) -or !(Test-Path $payloadWinSWXml)) {
  throw "Staging incompleto: no quedó WinSW en $payloadService"
}

Write-Host "OK staging listo." -ForegroundColor Green
