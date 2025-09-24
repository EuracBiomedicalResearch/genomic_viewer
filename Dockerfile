# Dockerfile

# Base R Shiny image
FROM rocker/shiny:4.4.3

# Make a directory in the container
RUN mkdir /shiny-app-GenomicViewer

# Install requirements
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
 liblzma-dev \
 libglpk40 \
 cmake \
 libglpk-dev \
 libicu-dev \
 libssl-dev \
 libxml2-dev 

# Install renv
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"


# Copy Renv files
WORKDIR /shiny-app-GenomicViewer/
RUN mkdir -p renv
COPY Docker_files/renv.lock renv.lock
COPY Docker_files/.Rprofile  .Rprofile
COPY Docker_files/renv/activate.R renv/activate.R
COPY Docker_files/renv/settings.json renv/settings.json

# Restore R packages
RUN R -e "renv::restore()"

RUN R -e "install.packages('R.utils', repos = c(CRAN = 'https://cloud.r-project.org'))"
# Copy the Shiny app files
COPY Docker_files/ /shiny-app-GenomicViewer/



# Expose the application port
EXPOSE 8180

# Run the R Shiny app
CMD Rscript /shiny-app-GenomicViewer/GenomicViewer_app.r



###---------------------------------------
