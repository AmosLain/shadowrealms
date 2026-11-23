@echo off
setlocal
cd /d "%~dp0"
set "engine=%GODOT_BIN%"
if not defined engine for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined engine set "engine=%%G"
if not defined engine for %%G in ("%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe") do if exist "%%~fG" set "engine=%%~fG"
if not defined engine (
 echo Open project.godot with Godot 4.7.2 or set GODOT_BIN to the Godot executable.
 pause
 exit /b 1
)
"%engine%" --headless --editor --import --path "."
if errorlevel 1 exit /b 1
"%engine%" --path "." %*

