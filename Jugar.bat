@echo off
set "MAAI_GODOT=D:\Trabajo\Programas\Para juegos\godot\Godot_v4.2.1-stable_win64.exe"
if not exist "%MAAI_GODOT%" (
  echo No se encontro Godot. Importa project.godot en Godot 4.2 o posterior.
  pause
  exit /b 1
)
start "MAAI" "%MAAI_GODOT%" --path "%~dp0."

