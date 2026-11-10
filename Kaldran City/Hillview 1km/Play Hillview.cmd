@echo off
setlocal
set "ENGINE=%~dp0..\..\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" set "ENGINE=%USERPROFILE%\OneDrive\Desktop\Project Z (Godot)\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" (
  echo Godot was not found in the Project Z folder.
  pause
  exit /b 1
)
pushd "%~dp0"
start "" /D "%CD%" "%ENGINE%" --path .
popd
