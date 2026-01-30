param(
  [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
)

$ErrorActionPreference = "Stop"

$wixBin = ${env:WIX}
if (-not $wixBin) {
  $candidates = @(
    "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    "C:\Program Files (x86)\WiX Toolset v3.11\bin"
  )
  $wixBin = ($candidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
}

if (-not $wixBin) {
  throw "No se encontró WiX bin. Instala WiX Toolset v3.x o setea env:WIX al path bin."
}

$candle = Join-Path $wixBin "candle.exe"
$light = Join-Path $wixBin "light.exe"
$heat  = Join-Path $wixBin "heat.exe"

if (!(Test-Path $candle) -or !(Test-Path $light) -or !(Test-Path $heat)) {
  throw "No se encontró WiX. Instala WiX Toolset v3.x y/o setea env:WIX al path bin."
}

function Invoke-Tool {
  param(
    [Parameter(Mandatory=$true)][string]$Exe,
    [Parameter(Mandatory=$true)][string[]]$Args
  )
  & $Exe @Args
  if ($LASTEXITCODE -ne 0) {
    throw "Falló: $Exe (exit=$LASTEXITCODE)"
  }
}

function Normalize-HeatOutput {
  param(
    [Parameter(Mandatory=$true)][string]$Path
  )
  if (!(Test-Path $Path)) { return }

  $content = Get-Content -Raw -LiteralPath $Path

  if ($content -match '\$\(PayloadDir\)') {
    $content = $content -replace '\$\(PayloadDir\)', '$(var.PayloadDir)'
  }

  if ($content -match 'Guid="PUT-GUID-HERE"') {
    $content = $content -replace 'Guid="PUT-GUID-HERE"', 'Guid="*"'
  }

  Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

$payloadRoot = Join-Path $RepoRoot "installer\dist\payload"
$payloadApp = Join-Path $payloadRoot "app"
$payloadService = Join-Path $payloadRoot "service"
if (!(Test-Path $payloadRoot)) {
  throw "No existe payload. Ejecuta primero: installer\\scripts\\stage.ps1"
}
if (!(Test-Path $payloadApp)) { throw "No existe payload\\app" }
if (!(Test-Path $payloadService)) { throw "No existe payload\\service" }

$outDir = Join-Path $RepoRoot "installer\dist"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$harvestAppWxs = Join-Path $outDir "Harvest.App.wxs"
$productWxs = Join-Path $RepoRoot "installer\wix\Product.wxs"

Write-Host "Harvesting app/ with heat..." -ForegroundColor Cyan
Invoke-Tool $heat @(
  "dir", $payloadApp,
  "-nologo",
  "-cg", "AppComponentGroup",
  "-dr", "APPDIR",
  "-srd",
  "-gg",
  "-sreg", "-scom", "-sfrag",
  "-var", "var.PayloadDir",
  "-out", $harvestAppWxs
)
Normalize-HeatOutput -Path $harvestAppWxs

# Candle/Light
$obj1 = Join-Path $outDir "Product.wixobj"
$obj2 = Join-Path $outDir "Harvest.App.wixobj"

Write-Host "Compiling wixobj..." -ForegroundColor Cyan
Invoke-Tool $candle @(
  "-nologo",
  "-out", $obj1,
  $productWxs
)

Invoke-Tool $candle @(
  "-nologo",
  "-dPayloadDir=$payloadApp",
  "-out", $obj2,
  $harvestAppWxs
)

$msi = Join-Path $outDir "MarCaribeSoftwareMatcher.msi"
Write-Host "Linking MSI..." -ForegroundColor Cyan
Invoke-Tool $light @(
  "-nologo",
  "-ext", "WixUtilExtension",
  "-out", $msi,
  $obj1, $obj2
)

if (!(Test-Path $msi)) {
  throw "No se generó el MSI esperado: $msi"
}

Write-Host "OK MSI generado -> $msi" -ForegroundColor Green
