@echo off
setlocal

REM Desinstala el SoftwareMatcher como servicio (WinSW).
REM Requiere ejecutar como Administrador.

set BASE=%~dp0dist\win-x64
set WINSW=%BASE%\MarCaribeSoftwareMatcher.exe

if not exist "%WINSW%" (
  echo Falta %WINSW%
  exit /b 1
)

echo Deteniendo servicio...
"%WINSW%" stop

echo Desinstalando servicio...
"%WINSW%" uninstall
if errorlevel 1 exit /b 1

echo OK. Servicio desinstalado.
