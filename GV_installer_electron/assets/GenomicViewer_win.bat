
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
  "sarlago/shiny-docker-genomicviewer2" 

REM -------- Open browser window --------  
 timeout /t 24 /nobreak > NUL 
REM start http://localhost:8180 

@echo off
setlocal

set URL=http://localhost:8180

:waitloop
REM Check if page responds with 200 OK
for /f "tokens=*" %%i in ('curl -s -o nul -w "%%{http_code}" %URL%') do set status=%%i

REM Detect failure: container no longer running
docker ps --filter "ancestor=sarlago/shiny-docker-genomicviewer2" --format "{{.ID}}" | findstr . >nul
if errorlevel 1 (
    set GV_ERROR=1
)

if "%status%"=="200" (
    echo GV is ready! Opening browser...
    start "" "%URL%"
    goto end
)

REM Print message only if no error has occurred
if "%GV_ERROR%"=="0" (
    echo Waiting for GV to start
)

timeout /t 1 >nul
goto waitloop
)

:end
echo Done.