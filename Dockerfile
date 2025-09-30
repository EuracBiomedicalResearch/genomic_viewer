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
 libxml2-dev \
 libtiff-dev \
 libwebp-dev 

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

# Install from local T2T knowngenes package
RUN R -e "install.packages('devtools', repos = c(CRAN = 'https://cloud.r-project.org'))"
COPY Docker_files/T2T_txdb/ /shiny-app-GenomicViewer/T2T_txdb/
RUN R -e "devtools::install('/shiny-app-GenomicViewer/T2T_txdb/TxDb.Hsapiens.UCSC.T2T.knownGene/inst/extdata/')"

# Copy the Shiny app files
COPY Docker_files/ /shiny-app-GenomicViewer/

# Expose the application port
EXPOSE 8180

# Run the R Shiny app
CMD Rscript /shiny-app-GenomicViewer/GenomicViewer_app.r



###---------------------------------------
