param(
  [string]$Configuration = "Release",
  [string]$Runtime = "win-x64",
  [string]$OutDir = (Join-Path $PSScriptRoot "dist\\win-x64")
)

$ErrorActionPreference = "Stop"

# RepoRoot = App-Web-Alimentos-SoftwareMatcher/
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." )).Path

Write-Host "Publishing SoftwareMatcher -> $OutDir" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# EXE single-file self-contained
# Nota: PublishTrimmed=false por seguridad (SourceAFIS + reflection/IL patterns)

dotnet publish (Join-Path $repoRoot "MatcherApi.csproj") `
  -c $Configuration `
  -r $Runtime `
  --self-contained true `
  -o $OutDir `
  /p:PublishSingleFile=true `
  /p:IncludeNativeLibrariesForSelfExtract=true `
  /p:PublishTrimmed=false

if ($LASTEXITCODE -ne 0) {
  throw "dotnet publish falló (exit=$LASTEXITCODE)"
}

Write-Host "OK. Output -> $OutDir" -ForegroundColor Green
Write-Host "Siguiente: ejecuta dist\\win-x64\\run.cmd en la PC destino" -ForegroundColor DarkCyan
