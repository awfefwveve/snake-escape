@echo off
cd /d "%~dp0"
start "" "%~dp0Game.exe" --path "%~dp0." --log-file "%~dp0game.log"
