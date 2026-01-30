@echo off
setlocal

REM Levanta el SoftwareMatcher en localhost:5100
set ASPNETCORE_URLS=http://127.0.0.1:5100

REM Umbral por defecto (puedes ajustar)
if "%SOURCEAFIS_THRESHOLD%"=="" set SOURCEAFIS_THRESHOLD=40

REM Ejecuta el EXE publicado
set EXE=%~dp0dist\win-x64\MatcherApi.exe
if not exist "%EXE%" (
  echo No existe: %EXE%
  echo Primero publica con windows\publish.ps1 (en PC con .NET SDK).
  exit /b 1
)

echo Iniciando SoftwareMatcher en %ASPNETCORE_URLS% (threshold=%SOURCEAFIS_THRESHOLD%)
"%EXE%"
