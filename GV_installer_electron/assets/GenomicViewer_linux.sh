#!/bin/bash

# -------- SILENT RUN OF DOCKER -----------

# 1. Check if docker CLI exists
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed on this system. Please install Docker before running this application."
    exit 1
fi

# 2. Check if system uses systemd
if command -v systemctl &>/dev/null; then
    
    # Check if Docker service exists on this machine
    if ! systemctl list-unit-files | grep -q docker.service; then
        echo "Docker service not found on this system."
        echo "If you're using rootless Docker, install and enable docker.service"
        exit 1
    fi

    # Check if Docker is already running
    if systemctl is-active --quiet docker; then
        echo "Docker is already running."
    else
        echo "Silently starting Docker..."

        # Check if user is in sudo or wheel group (can start services)
        if groups "$USER" | grep -qE '\b(sudo|wheel)\b'; then
            echo "Running as root. Starting docker service..."
             systemctl start docker || {
                echo "Failed to start Docker as root."
                exit 1
            }
        else
            echo "Running as non-root user. Attempting to start rootless Docker..."
            systemctl --user start docker.service || {
                echo "Failed to start rootless Docker. Make sure it is configured."
                exit 1
            }
        fi
    fi

else
    echo "systemd not found. Cannot manage Docker with systemctl."
    echo "Your system may be using sysvinit, openrc, or another init system."
    exit 1
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
sleep 20

# Open in default browser when app is ready
URL="http://127.0.0.1:8180"
while true; do
    # Get HTTP status code
    status=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
    if [[ "$status" == "200" ]]; then
        echo "GV is ready! Opening browser..."
        if command -v xdg-open &>/dev/null; then
			xdg-open $URL 2>&1 | tee out.log 
			
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

