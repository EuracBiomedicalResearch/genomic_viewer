#!/bin/bash -l

##########################################################
## Genomic Viewer for Mac                               ##
##########################################################

if [ "$1" = "" ] ;
  then
	########################################################################
	## Print usage
	echo "Usage: bash GenomicViewer-gui.run.sh <data_dir>"

  else
	dir=$(realpath $1)
		
	echo "Starting Docker Desktop..."
	echo "Data directory: ${dir}"
	# Wait for Docker to be ready
        open -a Docker 
	echo "Waiting for Docker to be ready..."
	until docker info &>/dev/null; do
	    echo "… still waiting for Docker..."
	    sleep 3
	done
	
	echo "Docker is ready."
	echo "Starting Genomic Viewer..."
	
	# -------- RUN THE SHINY APP -----------
	
	# Run the Docker container with volume mounted
	docker run --rm -p 8180:8180 \
	  -v "${dir}:/data" \
	  sarlago/shiny-docker-genomicviewer2 &
	
	# Give it time to boot up
	#sleep 25
	
	# Open default browser to access the app wgen page is ready
	#echo "Opening browser at http://localhost:8180"
	#open "http://localhost:8180"
	URL="http://localhost:8180"
	GV_ERROR=0
	
	while true; do
		    # Detect container failure (once)
	    if [[ "$GV_ERROR" -eq 0 ]]; then
	        if ! docker ps --filter "ancestor=sarlago/shiny-docker-genomicviewer2" \
	            --format '{{.ID}}' | grep -q .; then
	            GV_ERROR=1
	            echo "Genomic Viewer failed during startup. Waiting silently..."
	        fi
	    fi
		    # Get HTTP status code
	    status=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
	    if [[ "$status" == "200" ]]; then
	        echo "GV is ready! Opening browser..."
		open $URL 2>&1 | tee out.log 
	        # Loop until page is NOT available
	        while true; do
	            status=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
	            if [[ "$status" != "200" ]]; then
	                echo "Page is no longer available (status $status). Exiting."
	                exit 0
	            fi
	            sleep 2
	        done
	    fi
	
	    # Print waiting message only if no error occurred
	    if [[ "$GV_ERROR" -eq 0 ]]; then
	        echo "Waiting for GV... (status $status)"
	    fi
	
	    sleep 1
	done
fi
