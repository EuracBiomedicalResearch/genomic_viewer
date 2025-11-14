
@echo off
REM -------- SILENT RUN OF DOCKER -----------
setlocal

set DOCKER_PATH="%ProgramFiles%\Docker\Docker\Docker Desktop.exe"

REM Check if Docker Desktop is installed
if exist %DOCKER_PATH% (
    echo Starting Docker Desktop silently...
    start "" /min %DOCKER_PATH%
) else (
    echo Docker Desktop not found at %DOCKER_PATH%
)

REM Wait for Docker to be ready
:wait_for_docker
docker info >nul 2>&1
if errorlevel 1 (
    echo Waiting for Docker to start...
    timeout /t 3 >nul
    goto wait_for_docker
)

echo Docker is ready.
echo Starting Genomic Viewer... 
@echo off
REM -------- RUN THE SHINY APP -----------
REM Navigate to the directory of this .bat file
cd /d "%~dp0"

REM Run Docker with current directory mounted

start /b docker run --rm -p 8180:8180 ^
  -v "%cd%/data:/data" ^
  shiny-docker-genomicviewer2 
  
timeout /t 25 /nobreak > NUL 
start http://0.0.0.0:8180 
