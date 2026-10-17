@echo off
set "MAAI_GODOT=D:\Trabajo\Programas\Para juegos\godot\Godot_v4.2.1-stable_win64.exe"
if not exist "%MAAI_GODOT%" (
  echo No se encontro Godot. Abre el proyecto y selecciona Ver animaciones de Tsukiyo.
  pause
  exit /b 1
)
start "MAAI - Tsukiyo" "%MAAI_GODOT%" --path "%~dp0." -- --demo
