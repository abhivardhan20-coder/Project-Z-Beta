@echo off
setlocal
set "GODOT_EXE=%~dp0Godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
set "GAME_PROJECT=%~dp0PROJECT_Z"
if not exist "%GODOT_EXE%" (
    echo The Godot executable was not found alongside PROJECT_Z.
    pause
    exit /b 1
)
start "" "%GODOT_EXE%" --path "%GAME_PROJECT%" res://scenes/world/kaldran_pilot.tscn
