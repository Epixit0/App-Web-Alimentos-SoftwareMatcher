@echo off
setlocal

REM Instala el SoftwareMatcher como servicio usando WinSW.
REM Requiere ejecutar esta consola como Administrador.

set BASE=%~dp0dist\win-x64
set EXE=%BASE%\MatcherApi.exe
set WINSW=%BASE%\MarCaribeSoftwareMatcher.exe
set XML=%BASE%\MarCaribeSoftwareMatcher.xml

if not exist "%EXE%" (
  echo Falta %EXE%
  echo Primero publica con windows\publish.ps1
  exit /b 1
)

REM Copia/crea WinSW y XML si no existen
if not exist "%WINSW%" (
  echo Falta %WINSW%
  echo Copia el WinSW exe desde:
  echo   App-Web-Alimentos-Agent\installer\assets\winsw\MarCaribeFingerprintAgent.exe
  echo y renombralo a:
  echo   %WINSW%
  exit /b 1
)

if not exist "%XML%" (
  echo Falta %XML%
  echo Copia windows\winsw\MarCaribeSoftwareMatcher.xml a:
  echo   %XML%
  exit /b 1
)

echo Instalando servicio...
"%WINSW%" install
if errorlevel 1 exit /b 1

"%WINSW%" start
if errorlevel 1 exit /b 1

echo OK. Servicio instalado y iniciado: MarCaribeSoftwareMatcher
