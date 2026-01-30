# MSI (Windows) – MarCaribe SoftwareMatcher (SourceAFIS)

Objetivo: generar un instalador **MSI** para Windows que:

- Copie el SoftwareMatcher (.NET 8) a `Program Files`.
- Cree/instale un **Windows Service** que arranque con Windows.
- Levante el API en `http://127.0.0.1:5100`.

## Requisitos (solo en la PC donde compilas el MSI)

1) Windows 10/11 recomendado.
2) **.NET 8 SDK** instalado (para `dotnet publish`).
3) **WiX Toolset v3.x** instalado.
4) WinSW (wrapper de servicio).

### WinSW

Este MSI espera encontrar el wrapper en:

- `installer\assets\winsw\MarCaribeSoftwareMatcher.exe`

Si estás trabajando en el monorepo `MarCaribe`, el `stage.ps1` intenta copiarlo automáticamente desde:

- `..\App-Web-Alimentos-Agent\installer\assets\winsw\MarCaribeFingerprintAgent.exe`

## Paso 1 – Preparar staging (payload)

En PowerShell, desde la raíz del proyecto:

- `cd App-Web-Alimentos-SoftwareMatcher`
- `powershell -ExecutionPolicy Bypass -File .\installer\scripts\stage.ps1`

Esto genera:

- `installer\dist\payload\app\` (output de `dotnet publish`)
- `installer\dist\payload\service\` (WinSW + XML)

## Paso 2 – Compilar MSI

- `powershell -ExecutionPolicy Bypass -File .\installer\wix\build.ps1`

Salida:

- `installer\dist\MarCaribeSoftwareMatcher.msi`

## Instalación en otras PCs

- Doble click al MSI.
- El servicio queda como: `MarCaribeSoftwareMatcher`
- Prueba en el navegador:
  - `http://127.0.0.1:5100/health`

## Configuración

La configuración está embebida en el XML del servicio (WinSW):

- `ASPNETCORE_URLS=http://127.0.0.1:5100`
- `SOURCEAFIS_THRESHOLD=40`

Puedes cambiarlo editando el archivo instalado en:

- `C:\Program Files\MarCaribe\SoftwareMatcher\service\MarCaribeSoftwareMatcher.xml`

Luego reinicia el servicio.
