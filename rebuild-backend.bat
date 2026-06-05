@echo off
cd /d "%~dp0"
set CACHEBUST=%RANDOM%%RANDOM%%RANDOM%
echo [1/2] docker-compose build backend...
docker-compose build backend
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
echo [2/2] docker-compose up -d backend
docker-compose up -d backend
echo Done.
