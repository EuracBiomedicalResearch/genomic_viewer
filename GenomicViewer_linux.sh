#!/bin/bash

# -------- SILENT RUN OF DOCKER -----------
## Check if Docker already running
if command -v systemctl &>/dev/null && systemctl is-active --quiet docker; then
    echo "Docker is already running."
else
    echo "Silenty starting Docker..."
    sudo systemctl start docker
fi

# Wait for Docker to be ready
echo "Checking Docker status..."
until docker info &>/dev/null; do
    echo "Waiting for Docker to start..."
    sleep 3
done

echo "Docker is ready."
echo "Starting Genomic Viewer..."

# -------- RUN THE SHINY APP -----------
# Navigate to the directory of this .sh script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"

# Run Docker with current directory mounted
docker run --rm -p 8180:8180 \
  -v "${SCRIPT_DIR}/data:/data" \
  sarlago/shiny-docker-genomicviewer2 &

# Give it time to boot up
sleep 25

# Open in default browser
if command -v xdg-open &>/dev/null; then
    xdg-open http://0.0.0.0:8180
else
    echo "Please open your browser and go to: http://0.0.0.0:8180"
fi
