# SoftwareMatcher en Windows (sin PowerShell)

Este proyecto es un API .NET 8 (Kestrel) que expone:

- `GET /health`
- `POST /api/template`
- `POST /api/verify`
- `POST /api/identify`

## Opción A (recomendada): EXE single-file (doble click)

En una PC de build (con .NET 8 SDK):

1) Publica el ejecutable:

- Ejecuta `publish.ps1` (solo para build; el usuario final NO lo usa).

2) Copia el contenido de `dist\win-x64\` a la PC del biométrico.

3) En esa PC, arranca con doble click:

- `run.cmd`

Esto levanta el servicio en `http://127.0.0.1:5100`.

## Opción B: Servicio de Windows (WinSW)

Si no quieres que nadie “lo abra”, puedes instalarlo como servicio.

- Requiere permisos de administrador.
- Usa WinSW (el mismo wrapper que ya usa el Agent).

Pasos:

1) Genera `dist\win-x64\` (Opción A).
2) Copia el WinSW exe (renómbralo) y el XML:
   - `App-Web-Alimentos-Agent\installer\assets\winsw\MarCaribeFingerprintAgent.exe` -> `dist\win-x64\MarCaribeSoftwareMatcher.exe`
   - `windows\winsw\MarCaribeSoftwareMatcher.xml` -> `dist\win-x64\MarCaribeSoftwareMatcher.xml`
3) Ejecuta como admin:
   - `install-service.cmd`

Desinstalar:
- `uninstall-service.cmd`

## Configuración

Variables de entorno útiles:

- `ASPNETCORE_URLS=http://127.0.0.1:5100`
- `SOURCEAFIS_THRESHOLD=40`
