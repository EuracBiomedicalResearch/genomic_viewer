#!/bin/bash

# -------- SILENT RUN OF DOCKER -----------
# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Try to start Docker Desktop (only works if it's installed in Applications)
DOCKER_APP="/Applications/Docker.app"

if ! docker info &>/dev/null; then
    if [ -d "$DOCKER_APP" ]; then
        echo "Starting Docker Desktop..."
        open -a Docker
    else
        echo "Docker Desktop not found at $DOCKER_APP"
        exit 1
    fi
fi

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
until docker info &>/dev/null; do
    echo "… still waiting for Docker..."
    sleep 3
done

echo "Docker is ready."
echo "Starting Genomic Viewer..."

# -------- RUN THE SHINY APP -----------
# Navigate to the directory of this script .sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"

# Run the Docker container with volume mounted
docker run --rm -p 8180:8180 \
  -v "${SCRIPT_DIR}/data:/data" \
  sarlago/shiny-docker-genomicviewer2 &

# Give it time to boot up
sleep 25

# Open default browser to access the app wgen page is ready
echo "Opening browser at http://localhost:8180"
#open "http://localhost:8180"
URL="http://localhost:8180"

while true; do
    # Get HTTP status code
    status=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
    if [[ "$status" == "200" ]]; then
        echo "GV is ready! Opening browser..."
        open "$URL"      # macOS
		
		echo "Browser opened. Monitoring availability of $URL ..."
            # Loop until page is NOT available
            while true; do
                status=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
                if [[ "$status" != "200" ]]; then
                    echo "Page is no longer available (status $status). Exiting."
                    break
                fi
                sleep 2
            done

        else
            echo "Please open your browser and go to: $URL"
            echo "Waiting until $URL is not available anymore..."
            while true; do
                status=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
                if [[ "$status" != "200" ]]; then
                    echo "$URL is no longer available (status $status). Exiting."
                    break
                fi
                sleep 2
            done
        fi

        break
    else
        echo "Waiting for GV... (status $status)"
        sleep 1
    fi
done
