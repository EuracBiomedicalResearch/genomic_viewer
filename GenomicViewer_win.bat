

@echo off
REM Navigate to the directory of this .bat file
cd /d "%~dp0"

echo Starting Genomic Viewer...
REM Run Docker with current directory mounted
docker run --rm -p 8180:8180 ^
  -v "%cd%/data:/data" ^
  shiny-docker-genomicviewer
  
  
timeout /t 5 /nobreak > NUL
echo Opening browser...
start http://0.0.0.0:8081