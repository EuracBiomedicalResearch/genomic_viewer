
######----------------------------------------------------------- LOADING LIBRARIES
# Load shiny libraries and graphical (CRAN)
library(shiny)
library(bslib)
library(shinyjs)
library(svglite)
library(svgPanZoom)
library(paletteer)
library(shinycssloaders)
library(ggplot2)
library(ComplexUpset)
library(dplyr)
library(readr)
library(stringr)
library(sqldf)
library(ggpubr)
library(circlize)
library(ggraph)
library(igraph)
# Load server libraries (Bioconductor)
library(org.Hs.eg.db)
library(AnnotationHub)
library(ggchicklet) # github ok

library(plotgardener)
library(spiky)
library(TxDb.Hsapiens.UCSC.T2T.knownGene) # from local build
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(TxDb.Hsapiens.UCSC.hg19.knownGene)
library(TxDb.Mmusculus.UCSC.mm39.knownGene)
library(TxDb.Mmusculus.UCSC.mm10.knownGene)
library(rtracklayer)
library(ChIPpeakAnno) # bioconductor

#library(BSgenome.Hsapiens.NCBI.T2T.CHM13v2.0)
#library(BSgenome.Mmusculus.UCSC.mm39)


# Source script
source("plotgardener_function.r")
source("shiny_read_table_function.R")
source("basic_statistics_genome_tracks_function.r")

# Specify the application port
options(shiny.host = "0.0.0.0")
options(shiny.port = 8180)

#' Central switch to find out what type of application we are running.
#'
#' @returns `TRUE`, if the code is running inside the container, `FALSE` if
#' the code is running in a local development environment.
in.container <- function()
{
  return( Sys.getenv("GV_DEVELOPMENT")=="" )
}

######----------------------------------------------------------- READING DATSETS FROM CONFIG FILE
Sys.setenv(R_CONFIG_ACTIVE = "default")

if( in.container() ) {
  ## Load internal, not modifiable config file with genome annotations.
  config_gen <- config::get(file = "GenomicViewer_config_gen.yml")
  ## By putting "" at the beginning of the path, we make it append "/" and
  ## obtain an absolute path.
  usrConfPath <- file.path("", "data", "GenomicViewer_config.yml")
} else {
  config_gen <- list()
  usrConfPath <- file.path(Sys.getenv("HOME"), "projects", "eurac",
                           "genomic_viewer", "local",
                           "GenomicViewer_config.yml")
}

## Load config file and handle parsing errors like invalid YAML, bad indentation, missing ":".
config <- tryCatch(
  config::get(file = usrConfPath),
  error = function(e) {
    stop("#### CONFIGURATION ERROR #### \n GenomicViewer_config.yml: ", e$message, call. = FALSE)
  }
)

# Entries `chrom.cen.dir` and `genes.hgnc.dir` are hidden from the user. They
# are specified in the internal config file in the container version, but they
# need to be stated in the development version. We implement the following
# logic:
# - If there is one of these entries in the user-supplied config file, we take
#   it, even in the case of a container installation. That way we can perform an
#   override in the future.
# - If the respective key is missing in user-supplied config file in the
#   container version of the app, we copy the values of that key as defined in
#   the internal config file. This basically serves as a default/fallback. (If
#   these keys are missing in the developer version, we don't copy and will
#   throw an error when checking for missing keys below.)
# This is implemented for any key defined in the container internal config file,
# and applies specifically to `chrom.cen.dir` and `genes.hgnc.dir`.
if( in.container() )
  for( genKey in names(config_gen) )
    if( ! genKey %in% names(config) )
      config[[genKey]] <- config_gen[[genKey]]

# Validate required keys in config file (including those copied from the
# container version internal config file).
required.keys <- c("data.dir", "bw.dir", "bw.file", "bw.names", "bedpe.dir",
                   "bedpe.file", "bedpe.names", "bed.dir", "bed.file",
                   "bed.names", "hic.dir", "hic.file", "hic.names", "gwas.dir",
                   "gwas.file", "gwas.names", "cat.dir", "cat.file", "cat.names",
                   "reg.dir", "reg.file",
                   # Hidden from the user, specified in container internal cfg.
                   "chrom.cen.dir", "genes.hgnc.dir")
missing.keys <- setdiff(required.keys, names(config))

if (length(missing.keys) > 0) {
  stop(
    "#### CONFIGURATION ERROR #### \n Missing required config keys: ",
    paste(missing.keys, collapse = ", "),
    call. = FALSE
  )
}

# Ensure no data are loaded when values are empty
# Define group of keys for each file type
keys.prefix <- unique(sapply(strsplit(names(config),"\\."), `[`, 1))
keys.group <- lapply(keys.prefix, function(x) names(config)[grep(paste0(x, "\\."), names(config))])
# Check if are all empty
config.new <- c()
for (g in 1:length(keys.group)){
  if(all(unlist(lapply(keys.group[[g]], function(x) config[[x]] == "")) == TRUE)){
    # Replace with double space to avoid unwanted files being loaded
    config.entry <- lapply(keys.group[[g]], function(x) gsub("", "  ", config[[x]]))
    config.new <- c(config.new, config.entry)
  } else {
    config.entry <- lapply(keys.group[[g]], function(x) config[[x]])
    config.new <- c(config.new, config.entry)
  }
}
# Add key names to new config
names(config.new) <- names(config)
config <- config.new

# Validate expected extensions are correctly assigned to keys
# Define expected extensions for certain keys
expected.ext <- list(
  "bw.file"  = c(".bw", ".bigwig"),
  "bedpe.file" = ".bedpe",
  "bed.file" = c(".bed", ".bam", ".tsv", ".txt"),
  "hic.file" = c(".hic"),
  "gwas.file" = c(".tsv", ".txt"),
  "cat.file" = c(".bed", ".tsv", ".txt"),
  "reg.file" = c(".bed", ".txt", ".tsv")
)
compressed.ext <- c(".gz", ".zip", ".bz2", ".xz", ".tgz", ".tar")

# Check config keys
for (key in names(config)) {
  # Only process keys ending with .file
  if (grepl("\\.file$", key, ignore.case = TRUE)) {
    value <- config[[key]]
    # Skip if value is empty
    for (v in value){
      if (is.null(v) || v == "") next
      # Remove compression ext
      value <- gsub(paste(compressed.ext, collapse = "|"), "", v)
      # Get file extension including dot, lowercased
      ext <- paste0(".", tolower(tools::file_ext(v)))
      # Determine expected extensions for this key
      if (key %in% names(expected.ext)) {
        allowed <- expected.ext[[key]]
        # Default: accept any extension
        next
      } # Check if the extension is valid
      if (!(ext %in% tolower(allowed))) {
        stop(sprintf(
          "#### CONFIGURATION ERROR #### \n File extension error: '%s' should have extension %s but got '%s'.",
          key, paste(allowed, collapse = " or "), ext
        ))
      }
    }
  }
}

#' Get the content of a directory with matching file names.
#'
#' In directory [root]/[sub.dir] and lists all files in this directory matching
#' the regular expression `file.patt`. If the application is running inside
#' a container, we prefix the directory with `/` to have an absolute path.
#' @param root Root directory name.
#' @param sub.dir Subdirectory name.
#' @param file.patt Pattern to match file names against.
#' @return List of matched file names.
listDataDir <- function(root, sub.dir, file.patt)
{
  unlist(lapply(file.patt,
                function(pattern) {
                  search.path <- file.path(root, sub.dir)
                  if( in.container() ) {
                    search.path <- file.path("/", search.path)
                  }
                  dir(search.path, pattern = pattern,
                      recursive = TRUE, include.dirs = TRUE, full.names = TRUE)
                }))
}
## Read data from files listed in the config file.
# Set a BigWig file
bw.file <- listDataDir(config$data.dir, config$bw.dir, config$bw.file)
# Set a bed file
bedpe.file <- listDataDir(config$data.dir, config$bedpe.dir, config$bedpe.file)
# Set a bedpe file
bed.file <- listDataDir(config$data.dir, config$bed.dir, config$bed.file)
# Set hiC data file
hic.file <- listDataDir(config$data.dir, config$hic.dir, config$hic.file)
# Set GWAS data file
gwas.file <- listDataDir(config$data.dir, config$gwas.dir, config$gwas.file)
# Categorical bed file
cat.file <- listDataDir(config$data.dir, config$cat.dir, config$cat.file)
# Region Table file
saved.coord.path <- listDataDir(config$data.dir, config$reg.dir, config$reg.file)
saved.coord <- read_delim(saved.coord.path, "\t", col_names = F, show_col_types = F)
saved.coord <- apply(saved.coord, MARGIN = 1, function(x) paste(x, collapse = ":"))
saved.coord <- gsub(" ", "", saved.coord) # remove eventual white spaces
## Set options for bw file plotting mode:
bw.mode <- c("Profile", "Heatmap", "Profile and Heatmap")


######----------------------------------------------------------- SHINY

if( in.container() ) {
  shiny::addResourcePath('www', '/shiny-app-GenomicViewer/www')
  wwwPath <- "www/GV_logo.png"
} else {
  wwwPath <- "GV_logo.png"
}

# Define UI -----------------------------------------------------
ui <- page_sidebar(
  sidebar = sidebar(
    # graphics tags
    style = "background-color:#f2f0eb; height: 100%;",
    tags$style(type='text/css',
               ".selectize-dropdown-content{font-size: 85%;}
               .selectize-input { word-wrap : break-word;}
               .selectize-input { word-break: break-word;}"),
    width = 300,
    # text input to choose genomic coordinates:
    span("", img(src = wwwPath, height = 50,
                 style = "margin-left:14%; margin-top:-50px" )),
      # Reference genome
    selectInput("ref.genome", "Select reference genome", c("hg19 (GRCh37 - H. sapiens)",
                                                             "hg38 (GRCh38 - H. sapiens)",
                                                             "T2T (CHM13 - H. sapiens)",
                                                             "mm10 (GRCm38 - M. musculus)",
                                                             "mm39 (GRCm39 - M. musculus)"), selectize = F),
    card(tags$b("Insert coordinates:", style = "font-size: 90%; text-align:center"),
         # Chr
         tags$style(HTML(".selectize-dropdown-content {max-height: 100px !important;  /* ~5 items */
                                                    overflow-y: auto !important;   /* enable scrolling */
                                                    }"
         )),
         div(style="display:flex; align-items:center; gap:8px; margin-top:-20px; margin-left:-7px;",
             tags$label("chr", style="margin:0; padding-bottom:15px; width:19%; text-align:right;"),
             selectizeInput('chr', NULL, selected = "5", choices = c(as.character(seq(1:22)), "X", "Y"), multiple = F)
         ),
         # coordinates
         div(style="display:flex; align-items:center; gap:8px; margin-top:-30px; margin-left:-7px;",
             tags$label("start", style="margin:0; padding-bottom:15px; width:16%; text-align:right;"),
             numericInput(
               "chrstart",
               NULL,
               value = 28000000,
               min = 1,
               max = NA,
               width = "100%"
             )
         ),
         div(style="display:flex; align-items:center; gap:8px; margin-top:-30px; margin-bottom:-5px; margin-left:-7px;",
             tags$label("end", style="margin:0; padding-bottom:15px; width:19%; text-align:right;"),
             numericInput(
               "chrend",
               NULL,
               value = 28500000,
               min = 1,
               max = NA,
               width = "100%"
             )
         )),

    card(tags$b("Load/edit coordinates:", style = "font-size: 90%; text-align:center"),
         # Button to upload a user defined file of saved coordinates.
         tags$head(
           tags$style("
      .button-only-fileinput .shiny-file-input-progress
      {
        display: none;
      }
      .button-only-fileinput .btn-file {
        padding: 4px 8px;
        font-size: 88%;
        color: black;
        font-weight: 600;
        background-color:#f2f0eb;
      }
       .button-only-fileinput .form-control {
       padding: 2px 2px;
       font-size:88%;
       }
    ")
         ),
         div(class = "button-only-fileinput",
             fileInput("upload.coord", label = NULL, buttonLabel = "Upload...", multiple = F, accept = c(".bed", ".tsv", ".txt"), placeholder = "Config table loaded"),
             style="font-size:85%; padding: 1px 1px; margin-bottom: -17px; font-color: black; margin-top:-20px;"),

         # List of user-defined coordinates
         div(style="align-items:center; gap:10px; margin-top:-30px; margin-bottom:-10px;",
             tags$label("Select from menu", style="margin:0; padding-bottom:2px; padding-top:10px; text-align:left; font-size:90%;"),
             selectizeInput(
               inputId = "select",
               label = NULL,
               choices = saved.coord,
               multiple = F,
               selected = ""
             )),
         # Buttons to add, remove or export user defined coordinates
         fluidRow(div(style = "margin-left:2px; margin-right:7px; margin-top:-20px;",
                      div(style = "display:flex; justify-content:space-between; gap:0px;",
                          actionButton("add", "Add", width = "33%", style = "flex:1; font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white"),
                          actionButton("remove", "Remove", width = "33%", style = "flex:1; font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white"),
                          downloadButton("export", "Export", style = "flex:1; width: 33%; font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white")
                      )),
                  # Reset button
                  useShinyjs(),
                  column(width=12, align = "center", actionButton("reset.user.coord", "Reset", width = "40%",
                                                                  style = "font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white; margin-top:20px;"))
         ),
    ),

    div(style = "margin-left:5px; margin-rigth:5px; display:flex; justify-content:space-between; gap:2px;",
        # GO button
        tags$style(HTML("  #go {
    background-color: #494949;
    color: white;
    border: 1px solid #494949;
    border-radius: 4px;
    font-weight: 500;
  }
  #go:hover {
    background-color: #f2f0eb;
    color: #494949;
    border-color: #f2f0eb;
    border: 1px solid #494949;
    border-radius: 4px;
  }
")),
        actionButton("go", tags$b("Go"), style = "flex:1;"),

        # Download button
        actionButton("ask.download", "Save", icon = icon("download"), style = "flex:1;"),
    )),

  # Card
  page_fillable(
    layout_columns(
      navset_card_underline(
            title = "Selected genomic region",
            div(style = "overflow-y: hidden;", h6(textOutput("sel.coord"), style = "font-size:14px; padding:8px 8px;")),
              # Panel with plot ----------------------------------------------------------------------------------
            nav_panel("Plot", class = "gap-2 p-0 border-0 align-items-top margin-bottom-240px",
                      div(
                        style = "display:flex; flex-direction:column; height:100%;",
                        # Warning message in case there is no data
                        tags$head(tags$style(".shiny-output-error{visibility: hidden;}")),
                        tags$head(tags$style(".shiny-output-error:after{content: 'There is no data in this range. Try with different coordinates.'; visibility: visible; color: slategrey; position: absolute; top: 10px; left: 70px;}")),
                        # Notification of selected reference genome
                        uiOutput("current.ref"),
                        # SVG zoom button position
                        tags$head(tags$style(HTML("#res svg g#svg-pan-zoom-controls {
                                                    transform: translate(880px, 400px) scale(0.5) !important;
                                                  }"))),
                        # Main plot
                        div(
                          style = "flex-grow:1; overflow-y:auto;",
                          svgPanZoomOutput(outputId = "res", width = "auto", height = "auto") %>% withSpinner(color = "salmon", type = 6, size = 0.5),
                          imageOutput("plot.test", inline = T) %>% withSpinner(color = "salmon", type = 6, size = 0.5),#, width = "auto", height = "10px", inline=T) %>% withSpinner(color = "salmon", type = 6, size = 0.5),
                        ),
                        # Zoom section
                        div(id = "stickyBottomPanel", style="display:flex; flex-direction:column; width:100%",
                            plotOutput("plot", brush = brushOpts(id = "plot_brush", direction = c("x")), inline=T),
                            fluidRow(column(width = 2, h6(tags$b("Zoom-out:")), style = "text-align:right"),
                                     column(width = 1, actionButton("z2out", "2x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                                     column(width = 1,actionButton("z5out", "5x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                                     column(width = 1,actionButton("z10out", "10x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                                     column(width = 2, h6(tags$b("Zoom-in:")), style = "padding: 3px 5px; text-align:right"),
                                     column(width = 1,actionButton("z2in", "2x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                                     column(width = 1,actionButton("z5in", "5x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                                     column(width = 1,actionButton("z10in", "10x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px")
                            ) ) )
            ),
              # Panel with Table of data -------------------------------------------------------------------------
              nav_panel("Data", class = "gap-2 p-3 border-0 align-items-top",
                      # print table preview and download button: bed
                      uiOutput("view_bed") %>% withSpinner(type = 3, color.background = "white"),
                      uiOutput("bed_save"),
                      # print table preview and download button: bedpe
                      uiOutput("view_bedpe") %>% withSpinner(type = 3, color.background = "white"),
                      uiOutput("bedpe_save"),
                      # print table preview and download button: categorical bed
                      uiOutput("view_cat") %>% withSpinner(type = 3, color.background = "white"),
                      uiOutput("cat_save"),
                      # print table preview and download button: gwas
                      uiOutput("view_gwas") %>% withSpinner(type = 3, color.background = "white"),
                      uiOutput("gwas_save")
                        ),
               # Panel with Basic Statistics of data ------------------------------------------------------------
              nav_panel("Stats", class = "gap-2 p-3 border-0 align-items-top",
                # print plots of peaks numbers
                fluidRow(h6(tags$b("Peak counts")), tags$hr(), column(width = 6, plotOutput("peak.nr", height = 200) %>% withSpinner()),
                column(width = 6, plotOutput("arches.nr", height = 200) %>% withSpinner()), verbatimTextOutput('warn.message1')),
                # GO button peaks nr
                actionButton("run.stat1", "Run", width = "25%"),
                # print upset plot for peaks intersections
                fluidRow(plotOutput("upset", height = 400) %>% withSpinner(), verbatimTextOutput('warn.message2')),
                # GO button upset
                actionButton("run.stat2", "Run", width = "25%"),
                # print piechart with peaks annotation
                fluidRow(h6(tags$b("Peaks Annotation")),tags$hr(), plotOutput("annotation", height = "auto")  %>% withSpinner(), verbatimTextOutput('warn.message3')),
                # GO button annotation
                actionButton("run.stat3", "Run", width = "25%"),
                # print circos of 3D contacts
                fluidRow(h6(tags$b("Circos Plot 3D contacts")),tags$hr(), imageOutput("circos", width = "auto", height = 600, inline = T) %>% withSpinner(), verbatimTextOutput('warn.message6')),
                #fluidRow(h6(tags$b("Circos Plot 3D contacts")),tags$hr(), plotOutput("circos", height = 600) %>% withSpinner(), verbatimTextOutput('warn.message6')),
                # GO button circos
                actionButton("run.stat6", "Run", width = "25%"),
                # print circular hierarchy plot for categories
                fluidRow(h6(tags$b("Categorical classification")),tags$hr(), plotOutput("categories.pie", height = 350, width = 900) %>% withSpinner(), verbatimTextOutput('warn.message4')),
                # GO button circular hierarchy
                actionButton("run.stat4", "Run", width = "25%"),
                # print manhattan plot with whole chr and zoom-in
                fluidRow(h6(tags$b("Manhattan plot")),tags$hr(), plotOutput("manhattan", height = 600) %>% withSpinner(), verbatimTextOutput('warn.message5')),
                # GO button manhattan
                actionButton("run.stat5", "Run", width = "25%")
                  )),
      ##### Card with Chromosomes plot and other options --------------------------------------------------------
       card(card_header("Choose chromosome"),
            card_body(#class = "border-0 gap-1 align-items-bottom",
                      column(width=12, plotOutput("chr.plot", height = "130px", click = clickOpts(id = "chr.click", clip = T), hover = "chr.hover")),
                      div(verbatimTextOutput("chr.info"), style = "height:20px; font-size: 80%;"),
                      div(tags$b("Advanced Options:"), style = "text-align: center; margin-bottom: -10px;"),
                      # Search by gene
                      selectizeInput('gene.search', 'Search by gene', selected = "", choices = character(0), width = "100%"),
                      #textOutput('sel.gene'),
                      # Select mode for bigwig plotting
                      column(width = 12,
                      selectInput('bw.mode', "Select bigwig plot mode", bw.mode, selectize=FALSE, width = "100%"),
                      # Bigwig autoscale group options
                      actionButton("bw.autoscale", "Autoscale settings", width = "100%", style = "font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: #f2f0eb; border-color: slategrey;")),
                      # Select mode for categories plotting
                      selectInput('cat.mode', 'Select categories to expand', choices = config$cat.names, multiple = T, width = "100%"),
                      # Expand transcript track option
                      checkboxInput("checkbox", "Expand transcripts", FALSE),
                      # Show/Hide chromosome ideogram option
                      checkboxInput("checkideo", "Chromosome Ideogram", TRUE))
                ),
       col_widths = c(9, 3)
              )
              )

)

# Define SERVER logic ---------------------------------------------------
server <- function(input, output, session){

  ##---------------------- Read reference genome related files
  # Genes hgnc symbol
  genes.hgnc <- eventReactive(input$ref.genome, {
  genes.hgnc.path <- file.path(config$genes.hgnc.dir, paste(gsub( " .*", "", input$ref.genome), "_gene_symbol_cleaned.bed", sep=""))
  genes.hgnc <- read_delim(genes.hgnc.path, "\t", col_names = T, show_col_types = F)
  })

  ### For chromosomes plotting
  chrom.cen.df <- eventReactive(input$ref.genome, {
  chrom.cen.path <- file.path(config$chrom.cen.dir, paste("chrom_centromeres_", gsub( " .*", "", input$ref.genome), ".txt", sep=""))
  chrom.cen.df <- read_delim(chrom.cen.path, "\t", col_names = T, show_col_types = F)
  })

  ### For chromosome id drop down menu
  observeEvent(chrom.cen.df(), {
    chrom.cen.df <- chrom.cen.df()
    updateSelectizeInput(session = getDefaultReactiveDomain(), "chr", selected = gsub("chr", "", chrom.cen.df$chr)[1], choices = gsub("chr", "", chrom.cen.df$chr))#, options = list(maxOptions = 12), server = TRUE)
    print(input$chr)
  })

  ### For cytoband
  Cytoband <- eventReactive(input$ref.genome, {
    ref.genome <- gsub( " .*", "", input$ref.genome)
    if (ref.genome %in% c("hg19", "hg38", "mm10")){
      cytoband <- NULL
    } else if (ref.genome == "T2T"){
      cytoband <- read_delim(file.path(config$chrom.cen.dir, "chm13v2.0_cytobands_allchrs.bed"), delim = "\t", col_names = F)
      colnames(cytoband) <- c("seqnames", "start", "end", "name", "gieStain")
      return(cytoband)
    } else if (ref.genome == "mm39"){
      cytoband <- read_delim(file.path(config$chrom.cen.dir, "cytoBand_GRCm39.txt"), delim = "\t", col_names = F)
      colnames(cytoband) <- c("seqnames", "start", "end", "name", "gieStain")
      return(cytoband)
    }
  })


  ##---------------------- Establish reactive events
  reactiveChr <- eventReactive(input$go, {
    print(input$chr)
  })
  ## Chr start
  reactiveChrstart <- eventReactive(input$go, {
    if (is.na(input$chrstart) | input$chrstart <= 0) { print(1) }
    else {print(input$chrstart)}
  })
  ## Chr end
  reactiveChrend <- eventReactive(input$go, {
    chrom.cen.df <- chrom.cen.df()
    start <- reactiveChrstart()
    if (!is.na(input$chrend) & input$chrend > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) {
      print(chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])
    } else if (is.na(input$chrend) | input$chrend < 500) {
      print(start + 500)
    } else {
      print(input$chrend)
    }
  })
  ## Update Chr start end when unwanted values are entered
  observeEvent(input$go, {
    # handle start
    if (is.na(input$chrstart) | input$chrstart <= 0){
      updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = 1)
      start <- 1} else {start <- print(input$chrstart)}
    # handle end
    chrom.cen.df <- chrom.cen.df()
    if (!is.na(input$chrend) & input$chrend > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) {
      updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])
    } else if (is.na(input$chrend) | input$chrend - start <= 500 ) {
      updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = start + 500)}
  })
  ## Categories to expand
  reactiveCat <- reactive({
    exp.cat <- c(!config$cat.names %in% input$cat.mode)
  })

  ########################## CARD PLOT
  ##---------------------- Output selected coordinates text:
  output$sel.coord <- renderText({paste("chr", reactiveChr(), ": ", reactiveChrstart(), "-", reactiveChrend(), sep="")})
  ##---------------------- Show/hide current reference genome as warning for the user:
  plot.ready <- reactiveVal(FALSE)
  show.ref.message <- reactiveVal(TRUE)

  observeEvent(input$go, {
    plot.ready(TRUE)
    show.ref.message(FALSE)
  })

  observeEvent(input$ref.genome, {
    plot.ready(FALSE)
    show.ref.message(TRUE)
  })

  output$current.ref <- renderUI({
    if (!show.ref.message()) return(NULL)
    div("The current reference genome is: ", tags$strong(input$ref.genome), tags$br(), tags$em("Press Go to continue or choose the correct reference"))
  })

  ##---------------------- Output genomic view plot:
    tracks <- reactive({
      req(plot.ready())
      genes.hgnc <- genes.hgnc()
      req(sum((file.size(c(bw.file, bedpe.file, bed.file, hic.file, gwas.file, cat.file))))/2^30 <= 2 |
           sum((file.size(c(bw.file, bedpe.file, bed.file, hic.file, gwas.file, cat.file))))/2^30 >= 2 & (reactiveChrend() - reactiveChrstart()) <= 5e+05)
      plotgardener.shiny.function(bw.file = bw.file,
                                  hic.file = hic.file,
                                  bed.file = bed.file,
                                  bedpe.file = bedpe.file,
                                  bw.names = config$bw.names,
                                  hic.names = config$hic.names,
                                  bed.names = config$bed.names,
                                  bedpe.names = config$bedpe.names,
                                  gwas.file = gwas.file,
                                  gwas.names = config$gwas.names,
                                  cat.file = cat.file,
                                  cat.names = config$cat.names,
                                  cat.collapse = reactiveCat(),
                                  chr = reactiveChr(), #input$chr,
                                  start = reactiveChrstart(), #input$chrstart,
                                  end = reactiveChrend(), #input$chrend,
                                  bw.mode = input$bw.mode,
                                  bw.autoscale = grouped.bw.items(),
                                  expand.transcripts = reactiveTranscript(),
                                  genes.hgnc = genes.hgnc,
                                  genome = gsub( " .*", "", input$ref.genome),
                                  cytoband = Cytoband(),
                                  ideogram = reactiveIdeogram())
    # } else {return(NULL)}

    })

  output$res <- renderSvgPanZoom({
    #req(!is.null(tracks()))
    svgPanZoom(svglite:::inlineSVG(tracks()),
               panEnabled = T, controlIconsEnabled = T, viewBox = T, width = "auto", height = "900px") #width = "auto", height = "auto",
  })

  image <- reactive({
    req(plot.ready())
    genes.hgnc <- genes.hgnc()
    cond <- req(sum((file.size(c(bw.file, bedpe.file, bed.file, hic.file, gwas.file, cat.file))))/2^30 > 2 & (reactiveChrend() - reactiveChrstart()) > 5e+05)
    if (!cond) return(NULL)

    outfile <- tempfile(fileext='.png')
    png(outfile, width =1200, height=900, res = 120)
    plotgardener.shiny.function(bw.file = bw.file,
                                hic.file = hic.file,
                                bed.file = bed.file,
                                bedpe.file = bedpe.file,
                                bw.names = config$bw.names,
                                hic.names = config$hic.names,
                                bed.names = config$bed.names,
                                bedpe.names = config$bedpe.names,
                                gwas.file = gwas.file,
                                gwas.names = config$gwas.names,
                                cat.file = cat.file,
                                cat.names = config$cat.names,
                                cat.collapse = reactiveCat(),
                                chr = reactiveChr(), #input$chr,
                                start = reactiveChrstart(), #input$chrstart,
                                end = reactiveChrend(), #input$chrend,
                                bw.mode = input$bw.mode,
                                bw.autoscale = grouped.bw.items(),
                                expand.transcripts = reactiveTranscript(),
                                genes.hgnc = genes.hgnc,
                                genome = gsub( " .*", "", input$ref.genome),
                                cytoband = Cytoband(),
                                ideogram = reactiveIdeogram())
    dev.off()
    list(src = outfile,
         alt = "genomic viewer image")
    #} else {return(NULL)}
  })

  output$plot.test <- renderImage({
    req(image())
    image()
  }, deleteFile = F)

  ##-------------------- Output zooming region plot:

  output$plot <- renderPlot({
    x.ext <- (input$chrend - input$chrstart)*25/100
   p <- ggplot() +
      geom_rect(aes(xmin = input$chrstart - x.ext, xmax = input$chrend + x.ext, ymin = 10, ymax = 11), fill = "grey") +
      geom_rect(aes(xmin = input$chrstart, xmax = input$chrend, ymin = 10, ymax = 11), fill = "salmon", colour = "darkred") +
      theme_void() +
      theme(axis.text.x = element_text(size = 12),
            axis.ticks.x = element_line(),
            legend.position = "none",
            axis.title.x = element_text(face = "bold", size=15),
            plot.margin = unit(c(0,0,0.25,0), "cm"))
    p
  },
  width = "auto",
  height = 35
 )

  ##-------------------- Zooming when click on zoom buttons:
  ########## ZOOM-OUT
   ## Zoom out 2x
   observe({
     chrom.cen.df <- chrom.cen.df()
      zoom <- round((input$chrend - input$chrstart)/2, 0)
      s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart - zoom)
      e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend + zoom)
      # Modify if values exceed chr size
      if (input$chrstart - zoom <= 0){
        s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
      if ( input$chrend + zoom > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){
        e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) }
      }) %>%  bindEvent(input$z2out)
   ## Zoom out 5x
   observe({
     chrom.cen.df <- chrom.cen.df()
     zoom <- round(((input$chrend - input$chrstart)/2)*5, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend + zoom)
     # Modify if values exceed chr size
     if (input$chrstart - zoom <= 0){
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
     if ( input$chrend + zoom > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) }
     }) %>%  bindEvent(input$z5out)
   ## Zoom out 10x
   observe({
     chrom.cen.df <- chrom.cen.df()
     zoom <- round(((input$chrend - input$chrstart)/2)*10, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend + zoom)
     # Modify if values exceed chr size
     if (input$chrstart - zoom <= 0){
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
     if ( input$chrend + zoom > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) }
     }) %>%  bindEvent(input$z10out)
   ########## ZOOM-IN
   ## Zoom out 2x
   observe({
     chrom.cen.df <- chrom.cen.df()
     zoom <- round(((input$chrend - input$chrstart)/2)/2, 0)
     mid.region <- input$chrstart + round(((input$chrend - input$chrstart)/2), 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = mid.region - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = mid.region + zoom)
     # Modify if values exceed chr size
     if ((input$chrend - input$chrstart) <= 500){
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart)
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }
     }) %>%  bindEvent(input$z2in)
   ## Zoom out 5x
   observe({
     chrom.cen.df <- chrom.cen.df()
     zoom <- round(((input$chrend - input$chrstart)/5)/2, 0)
     mid.region <- round(input$chrstart + ((input$chrend - input$chrstart)/2), 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = mid.region - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = mid.region + zoom)
     # Modify if values exceed chr size
     if ((input$chrend - input$chrstart) <= 500){
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart)
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }
     }) %>%  bindEvent(input$z5in)
   ## Zoom out 10x
   observe({
     chrom.cen.df <- chrom.cen.df()
     zoom <- round(((input$chrend - input$chrstart)/10)/2, 0)
     mid.region <- round(input$chrstart + ((input$chrend - input$chrstart)/2), 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = mid.region - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = mid.region + zoom)
     # Modify if values exceed chr size
     if ((input$chrend - input$chrstart) <= 500){
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart)
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }
     }) %>%  bindEvent(input$z10in)



  ##-------------------- Update chr start end upon click on zoomed range
  observeEvent(input$plot_brush, {
    chrom.cen.df <- chrom.cen.df()
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x <- input$plot_brush
    # Define START min
    s <- updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = round(x$xmin, 0))
    if (x$xmin <= 0){
      s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
    # Define END max
    e <- updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = round(x$xmax, 0))
    if ( x$xmax > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){
      e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])}
    # Define SMALLER RANGE
    if ((x$xmax - x$xmin) <= 500){
      s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart)
      e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }

    session$resetBrush("plot_brush")
  })


  ########################## CARD DATA
  ######################################################## DATA TAB

  datasetTables <- reactive({

                data.table <- shiny_read_table_function(bed.file = bed.file,
                                         bedpe.file = bedpe.file,
                                         cat.file = cat.file,
                                         gwas.file = gwas.file,
                                         chr = reactiveChr(),
                                         Start = reactiveChrstart(),
                                         End = reactiveChrend())

                data.table
  })

  ######################################################## DATA TAB
  ###### Bed file table view

  # Rendering tables dependent on user input.
  observeEvent(length(bed.file), {
    x <- c(1:length(bed.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0('bed', i)]] <- renderTable({
        tryCatch(head(datasetTables()[[1]][[i]], n = 15),error = function(e) {print("Press GO to visualize data")})
      }, caption = config$bed.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })

  })

  # Rendering UI and outputtign tables dependent on user input.
  output$view_bed <- renderUI({
    x <- c(1:length(bed.file))
    lapply(x[!x == 0], function(i) {
      uiOutput(paste0('bed', i))
      })
  })


  # Download peaks
  observeEvent(length(bed.file),{
    x <- c(1:length(bed.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0("downloadBed", i)]] <- downloadHandler(
        filename = function(){paste0(config$bed.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".bed")},
        content = function(file){
          write.table(datasetTables()[[1]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })

  output$bed_save <- renderUI({
    x <- c(1:length(bed.file))
    lapply(x[!x == 0], function(i) {
      downloadButton(paste0("downloadBed", i), paste0("Download ", config$bed.names[i]))
    })
  })


  ###### Bedpe file table view

  # Rendering tables dependent on user input.
  observeEvent(length(bedpe.file), {
    x <- c(1:length(bedpe.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0('bedpe', i)]] <- renderTable({
        tryCatch(head(datasetTables()[[2]][[i]], n = 15),error = function(e) {print("Press GO to visualize data")})
      }, caption = config$bedpe.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })
  })

  # Rendering UI and outputting tables dependent on user input.
  output$view_bedpe <- renderUI({
    x <- c(1:length(bedpe.file))
    lapply(x[!x == 0], function(i) {
      uiOutput(paste0('bedpe', i))
    })
  })


  # Download arches
  observeEvent(length(bedpe.file),{
    x <- c(1:length(bedpe.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0("downloadBedpe", i)]] <- downloadHandler(
        filename = function(){paste0(config$bedpe.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".bedpe")},
        content = function(file){
          write.table(datasetTables()[[2]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })

  output$bedpe_save <- renderUI({
    x <- c(1:length(bedpe.file))
    lapply(x[!x == 0], function(i) {
      downloadButton(paste0("downloadBedpe", i), paste0("Download ", config$bedpe.names[i]))
    })
  })


  ###### Categorical bed file table view

  # Rendering tables dependent on user input.
  observeEvent(length(cat.file), {
    x <- c(1:length(cat.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0('cat', i)]] <- renderTable({
        tryCatch(head(datasetTables()[[3]][[i]], n = 15),error = function(e) {print("Press GO to visualize data")})
      }, caption = config$cat.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })
  })

  # Rendering UI and outputtign tables dependent on user input.
  output$view_cat <- renderUI({
    x <- c(1:length(cat.file))
    lapply(x[!x == 0], function(i) {
      uiOutput(paste0('cat', i))
    })
  })


  # Download categorical peaks
  observeEvent(length(cat.file),{
    x <- c(1:length(cat.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0("downloadCat", i)]] <- downloadHandler(
        filename = function(){paste0(config$cat.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".tsv")},
        content = function(file){
          write.table(datasetTables()[[3]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })

  output$cat_save <- renderUI({
    x <- c(1:length(cat.file))
    lapply(x[!x == 0], function(i) {
      downloadButton(paste0("downloadCat", i), paste0("Download ", config$cat.names[i]))
    })
  })


  ###### GWAS file table view

  # Rendering tables dependent on user input.
  observeEvent(length(gwas.file), {
    x <- c(1:length(gwas.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0('gwas', i)]] <- renderTable({
        tryCatch(head(datasetTables()[[4]][[i]], n = 15), error = function(e) {print("Press GO to visualize data")})
      }, caption = config$gwas.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })
  })

  # Rendering UI and outputting tables dependent on user input.
  output$view_gwas <- renderUI({
    x <- c(1:length(gwas.file))
    lapply(x[!x == 0], function(i) {
      uiOutput(paste0('gwas', i))
    })
  })


  # Download GWAS
  observeEvent(length(gwas.file),{
    x <- c(1:length(gwas.file))
    lapply(x[!x == 0], function(i) {
      output[[paste0("downloadgwas", i)]] <- downloadHandler(
        filename = function(){paste0(config$gwas.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".tsv")},
        content = function(file){
          write.table(datasetTables()[[4]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })

  output$gwas_save <- renderUI({
    x <- c(1:length(gwas.file))
    lapply(x[!x == 0], function(i) {
      downloadButton(paste0("downloadgwas", i), paste0("Download ", config$gwas.names[i]))
    })
  })

  ######################################################## STATS TAB
  vals <- reactiveValues(bed.file=NULL, bedpe.file=NULL, chr = "1", start = 28000000, end = 28500000)
  ## For bed files peak count
  observeEvent(input$run.stat1, {
    vals$bed.file <- bed.file[which(file.size(bed.file) <= 45e+06)]
    vals$bedpe.file <- bedpe.file[which(file.size(bedpe.file) <= 45e+06)]
    vals$chr <-  input$chr
    vals$start <- input$chrstart
    vals$end <- input$chrend
    # Specifiy if data not plotted in warning message
    large.data <- c(config$bed.names[which(file.size(bed.file) > 45e+06)], config$bedpe.names[which(file.size(bedpe.file) > 45e+06)])
    if(!isEmpty(large.data)){
      output$warn.message1 <- renderText({paste(large.data,"data larger than", ceiling(400e+06/2^20), "Mb not plotted",  collapse = " ")})
    }
  })


    output$peak.nr <- renderPlot({
            if(!is.null(vals$bed.file) & length(vals$bed.file) > 0){
        basic_statistics_genome_tracks(bed.file = vals$bed.file,
                                     bed.names = config$bed.names[which(file.size(bed.file) < 400e+06)],
                                     chr = vals$chr,
                                     Start = vals$start,
                                     End = vals$end,
                                     filetype = "bed")
      }
    }, res = 100)




  ## For bedpe files peak count
    output$arches.nr <- renderPlot({
      if(!is.null(vals$bedpe.file) & length(vals$bedpe.file) > 0){
       basic_statistics_genome_tracks(bed.file = vals$bedpe.file,
                                   bed.names = config$bedpe.names[which(file.size(bedpe.file) <= 45e+06)],
                                   chr = vals$chr,
                                   Start = vals$start,
                                   End = vals$end,
                                   filetype = "bedpe")
      }
    }, res = 100)
  ## For upset plot
    vals2 <- reactiveValues(bed.file=NULL, bedpe.file=NULL, chr = "1", start = 28000000, end = 28500000)

    observeEvent(input$run.stat2, {
      vals2$bed.file <- bed.file[which(file.size(bed.file) <= 45e+06)]
      vals2$bedpe.file <- bedpe.file[which(file.size(bedpe.file) <= 45e+06)]
      vals2$chr <-  input$chr
      vals2$start <- input$chrstart
      vals2$end <- input$chrend
      # Specifiy if data not plotted in warning message
      large.data <- c(config$bed.names[which(file.size(bed.file) > 45e+06)], config$bedpe.names[which(file.size(bedpe.file) > 45e+06)])
      if(!isEmpty(large.data)){
        output$warn.message2 <- renderText({paste(large.data,"data larger than", ceiling(45e+06/2^20), "Mb not plotted",  collapse = " ")})
      }
    })

    output$upset <- renderPlot({
      if(!is.null(vals2$bed.file) & !is.null(vals2$bedpe.file) & length(vals2$bed.file) > 0 & length(vals2$bedpe.file) > 0 |
         !is.null(vals2$bed.file) & length(vals2$bed.file) > 1 | !is.null(vals2$bedpe.file) & length(vals2$bedpe.file) > 1){
        peaks_intersection_venn_function(bed.file = vals2$bed.file,
                                      bed.names = config$bed.names[which(file.size(bed.file) < 45e+06)],
                                       bedpe.file = vals2$bedpe.file,
                                       bedpe.names = config$bedpe.names[which(file.size(bedpe.file) < 45e+06)],
                                       chr = vals2$chr,
                                       Start = vals2$start,
                                       End = vals2$end,
                                      genome = gsub( " .*", "", input$ref.genome))
      }
    }, res = 100)

  ## For annotation plot
    vals3 <- reactiveValues(bed.file=NULL)

    observeEvent(input$run.stat3, {
      vals3$bed.file <- bed.file[which(file.size(bed.file) <= 45e+06)]
      # Specifiy if data not plotted in warning message
      large.data <- c(config$bed.names[which(file.size(bed.file) > 45e+06)])
      if(!isEmpty(large.data)){
        output$warn.message3 <- renderText({paste(large.data,"data larger than", ceiling(45e+06/2^20), "Mb not plotted",  collapse = " ")})
      }
    })

    output$annotation <- renderPlot({
      if(!is.null(vals3$bed.file) & length(vals3$bed.file) > 0){
        peaks.annotation.function(bed.file = vals3$bed.file,
                                  bed.names = config$bed.names[which(file.size(bed.file) < 45e+06)],
                                  genome = gsub( " .*", "", input$ref.genome))
      }
    }, res = 100,
       height = function(){150*length(bed.file)})

    ## For circos plot
    vals6 <- reactiveValues(bedpe.file=NULL, chr = "1", start = 28000000, end = 28500000)

    observeEvent(input$run.stat6, {
      vals6$bedpe.file <- bedpe.file[which(file.size(bedpe.file) <= 400e+06)]
      vals6$chr <-  input$chr
      vals6$start <- input$chrstart
      vals6$end <- input$chrend
      # Specifiy if data not plotted in warning message
      large.data <- c(config$bedpe.names[which(file.size(bedpe.file) > 400e+06)])
      if(!isEmpty(large.data)){
        output$warn.message6 <- renderText({paste(large.data,"data larger than", ceiling(400e+06/2^20), "Mb not plotted",  collapse = " ")})
      }
    })

   # output$circos <- renderPlot({
    #  if(!is.null(vals6$bedpe.file) & length(vals6$bedpe.file) > 0){
     #   circos.function(bedpe.file = vals6$bedpe.file,
      #                  chromosome = vals6$chr,
       #                 genome = "hg38",
        #                zoom_start = vals6$start,
         #               zoom_end = vals6$end,
          #              genes.label = genes.hgnc,
           #             bedpe.names = config$bedpe.names[which(file.size(bedpe.file) < 45e+06)])
  #    }
   # }, res = 100)

    circos.image <- reactive({
      genes.hgnc <- genes.hgnc()
      if(!is.null(vals6$bedpe.file) & length(vals6$bedpe.file) > 0){
        outfile2 <- tempfile(fileext='.png')
        png(outfile2, width = 900, height = 1200, res = 120)
        circos.function(bedpe.file = vals6$bedpe.file,
                        chromosome = vals6$chr,
                        genome = gsub( " .*", "", input$ref.genome),
                        zoom_start = vals6$start,
                        zoom_end = vals6$end,
                        genes.label = genes.hgnc,
                        bedpe.names = config$bedpe.names[which(file.size(bedpe.file) < 45e+06)],
                        cytoband.ext = Cytoband())
        dev.off()
        list(src = outfile2,
             alt = "circos image")
      }
    })

    output$circos <- renderImage({
          req(!is.null(circos.image()))
      circos.image()
    }, deleteFile = T)


    ## For categories hierarchy plot
    vals4 <- reactiveValues(cat.file=NULL, chr = "1", start = 28000000, end = 28500000)

    observeEvent(input$run.stat4, {
      vals4$cat.file <- cat.file[which(file.size(cat.file) <= 400e+06)]
      vals4$chr <-  input$chr
      vals4$start <- input$chrstart
      vals4$end <- input$chrend
      # Specify if data not plotted in warning message
      large.data <- c(config$cat.names[which(file.size(cat.file) > 400e+06)])
      if(!isEmpty(large.data)){
        output$warn.message4 <- renderText({paste(large.data,"data larger than", ceiling(400e+06/2^20), "Mb not plotted",  collapse = " ")})
      }

    })
    output$categories.pie <- renderPlot({
      if(!is.null(vals4$cat.file) & length(vals4$cat.file) > 0){
        categorical.pie.function(cat.file = vals4$cat.file,
                                 cat.names = config$cat.names[which(file.size(cat.file) < 400e+06)],
                                 chr = vals4$chr,
                                 Start = vals4$start,
                                 End = vals4$end)
      }
    })

    ## For Manhattan plot
    vals5 <- reactiveValues(gwas.file=NULL, chr = "1", start = 28000000, end = 28500000)

    observeEvent(input$run.stat5, {
      vals5$gwas.file <- gwas.file[which(file.size(gwas.file) <= 800e+06)]
      vals5$chr <-  input$chr
      vals5$start <- input$chrstart
      vals5$end <- input$chrend
      # Specifiy if data not plotted in warning message
      large.data <- c(config$gwas.names[which(file.size(gwas.file) > 800e+06)])
      if(!isEmpty(large.data)){
        output$warn.message5 <- renderText({paste(large.data,"data larger than", ceiling(800e+06/2^20), "Mb not plotted",  collapse = " ")})
      }
    })
    output$manhattan <- renderPlot({
      if(!is.null(vals5$gwas.file) & length(vals5$gwas.file) > 0){
        manhattan.plot.function(gwas.file = vals5$gwas.file,
                              Chr = vals5$chr,
                              start = vals5$start,
                              end = vals5$end,
                              sign.p = 10e-8,
                              chr.len.df = chrom.cen.df(),
                              gwas.names =config$gwas.names[which(file.size(gwas.file) < 800e+06)],
                              genome = gsub( " .*", "", input$ref.genome))
        }
      }, res = 100)



  ##--------------------- Chromosome plot and additional options
    ## Plot
  output$chr.plot <- renderPlot({
    chrom.cen.df <- chrom.cen.df()
     ggplot(chrom.cen.df) +
      ggchicklet:::geom_rrect(aes(xmin = order - 0,
                                  xmax = order + 0.5,
                                  ymin = cen.start,
                                  ymax = chr.len,
                                  fill = chr)) +
      ggchicklet:::geom_rrect(aes(xmin = order - 0.,
                                  xmax = order + 0.5,
                                  ymin = 0,
                                  ymax = cen.end,
                                  fill = chr)) +
      scale_x_continuous(breaks = c(1:length(chrom.cen.df$chr)), labels = factor(chrom.cen.df$chr, levels = chrom.cen.df$chr)) +
      theme_void() +
      theme(legend.position = "none",
            axis.ticks.x = element_line(linewidth = 2, linetype = 2),
            axis.text.x = element_text(angle = 90, face = "bold", vjust = 1))

  }, height = 150, width = "auto")

  ## Hover output

  output$chr.info <- renderText({
    chrom.cen.df <- chrom.cen.df()
    if(!is.null(input$chr.hover)){
      hover=input$chr.hover
      if (floor(as.numeric(hover[1],0)) >= 1) {
        if(as.numeric(hover[2]) <= chrom.cen.df$chr.len[which(chrom.cen.df$chr == chrom.cen.df$chr[floor(as.numeric(hover[1],0))])]) {
          paste0(chrom.cen.df$chr[round(floor(as.numeric(hover[1],0)))], ": click to select")
        }
      }
    }

  })

  ## Update chr start end upon click on chr plot

  observeEvent(input$chr.click, {
    chrom.cen.df <- chrom.cen.df()
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x2 <- input$chr.click
    if (x2$x >= 1){
      if(x2$y <= chrom.cen.df$chr.len[which(chrom.cen.df$chr == chrom.cen.df$chr[x2$x])]){
        updateTextInput(session = getDefaultReactiveDomain(), "chr", value = gsub("chr", "", chrom.cen.df$chr[x2$x]))
        updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = 1)
        updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == chrom.cen.df$chr[x2$x])])
      }
    }
  })
  ##--------------------- END OF Chromosome plot and additional options

  ##------------------------ Search by gene

  gene.names <- reactive({
    if (!input$gene.search == ""){
    sel.gene <- input$gene.search
    }
  })

  observeEvent(genes.hgnc(), {
    genes.hgnc <- genes.hgnc()
    updateSelectizeInput(session = getDefaultReactiveDomain(), "gene.search", selected = "", choices = genes.hgnc$gene_symbol, server = TRUE)
  })

  #output$sel.gene <- renderText({input$gene.search})

  observeEvent(gene.names(),{
    if (!input$gene.search == ""){
    genes.hgnc <- genes.hgnc()
    updateTextInput(session = getDefaultReactiveDomain(), "chr", value = genes.hgnc$chromosome_name[which(genes.hgnc$gene_symbol == input$gene.search)])
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = genes.hgnc$start_position[which(genes.hgnc$gene_symbol == input$gene.search)])
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = genes.hgnc$end_position[which(genes.hgnc$gene_symbol == input$gene.search)])
    shinyjs::delay(100, shinyjs::click("go"))
    }
  })
  ##------------------------ END OF Search by gene

  ##------------------------ Expand transcripts checkbox
  reactiveTranscript <- eventReactive(input$checkbox, {
    print(input$checkbox)
  })
  ##------------------------ END OF Expand transcripts checkbox

  ##------------------------ Show chromosome Ideogram checkbox
  reactiveIdeogram <- eventReactive(input$checkideo, {
    print(input$checkideo)
  })
  ##------------------------ END OF chromosome Ideogram checkbox

  ##----------------------- User selected coordiates REGION TABLE
  ##----------------------- START OF User selected coordinates REGION TABLE
  coord <- reactive({
    if (!is.null(saved.coord) & is.null(input$upload.coord)){
      coord <- saved.coord
    } else if (!is.null(input$upload.coord)){
      up.coord.path <- input$upload.coord
      # test format of input file:
      coord <- tryCatch(
        read_delim(up.coord.path$datapath, "\t", col_names = F, show_col_types = F),
        error = function(e) NULL
      )
      # If reading failed
      if (is.null(df)) {
        showNotification("Could not read the file. Make sure it's a tab-separated file.", type = "error")
        return()
      }
      # If reading good: Validate column classes
      valid.2col <- (ncol(coord) == 2 && is.character(coord[[1]]) && is.numeric(coord[[2]]))
      valid.3col <- (ncol(coord) > 2 && is.character(coord[[1]]) && is.numeric(coord[[2]]) && is.numeric(coord[[3]]))
      # ---- Warning if not valid ----
      if (!(valid.2col || valid.3col)) {
        showNotification("Invalid format: must contain at least 3 columns (string, number, number).", type = "warning", duration = 7)
        return()
      }
      # ---- If valid, continue processing ----
      showNotification("File format accepted!", type = "message")
      # read the uploaded region table
      coord <- apply(coord, MARGIN = 1, function(x) paste(x, collapse = ":"))
      coord <- gsub(" ", "", coord) # remove eventual white spaces
    }
  })
    # if there is a coord file update the list from which the used can select
    observeEvent(coord(), {
      coord <- coord()
      updateSelectizeInput(session = getDefaultReactiveDomain(), "select", selected = "", choices = coord, options = list(maxOptions = 20, dropdownParent = 'body'), server = TRUE)
    })
    # transform coordinates form loaded table to usable array
    pass.coord <- reactive({
      if (!input$select == ""){
        pass <- unlist(strsplit(input$select, ":"))
      }
    })
    # Pass the parsed coordinates to the tool for visualization
    observeEvent(pass.coord(),{
      if (!input$select == ""){
        pass.coord <- pass.coord()
        updateTextInput(session = getDefaultReactiveDomain(), "chr", value = gsub("chr", "", pass.coord[1]))
        updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = as.numeric(pass.coord[2]))
        updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = as.numeric(pass.coord[3]))
      }
    })

    ################################## ACTIONS ON THE COORDINATES FROM THE USER DEFINED LIST ###############################

    # initialize coordinates list based on user selection
    coord.list <- reactiveVal(value = saved.coord)
    #print(coord.list)
    observeEvent(input$upload.coord, {
      user.coord <- coord.list(coord())
      #print(coord.list)
    })

    # Reset user defined region table
    observeEvent(input$reset.user.coord, {
      reset("upload.coord")
      updateSelectizeInput(session = getDefaultReactiveDomain(), "select", selected = "", choices = saved.coord, options = list(maxOptions = 20, dropdownParent = 'body'), server = TRUE)
    })

    #####----------------- ADD visualized coordinates to coordinates list
    ## Save coordinates to variables
    ## Chr
    chrNew <- eventReactive(input$add, {
      print(input$chr)
    })
    ## Chr start
    chrstartNew <- eventReactive(input$add, {
      if (!is.na(input$chrstart) & input$chrstart <= 0) {
        print(1)
      } else if (is.na(input$chrstart)) {
        print(1)
      } else {
        print(input$chrstart)
      }
    })
    ## Chr end
    chrendNew <- eventReactive(input$add, {
      chrom.cen.df <- chrom.cen.df()
      if (!is.na(input$chrend) & input$chrend > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) { print(chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])
      } else if (!is.na(input$chrend) & input$chrend < 0) {
        chrstartNew <- chrstartNew()
        print(chrstartNew + 500)
      } else if (is.na(input$chrend)){
        chrstartNew <- chrstartNew()
        print(chrstartNew + 500)
      } else print(input$chrend)
    })
    ## Ref gen
    refgenNew <- eventReactive(input$add, {
      if (!is.na(input$ref.genome)) {
        print(sapply(strsplit(input$ref.genome," "), `[`, 1))
      } else {
        print("")
      }
    })

    ## Add coordinates to Selectize drop-down list
    ### Aggiungerle solo se non é giá presente la stessa coordinata
    observeEvent(input$add,{
      chrNew <- chrNew()
      chrstartNew <- chrstartNew()
      chrendNew <- chrendNew()
      coord.list <- coord.list()
      coord.new <- c(coord.list, paste(paste("chr", chrNew, sep=""), chrstartNew, chrendNew, sep=":"))
      #print(coord.new)
      if (isEmpty(grep(coord.new[length(coord.new)], coord.list))){
        # updateSelectizeInput(session = getDefaultReactiveDomain(), "select", selected = "", choices = coord.new, options = list(maxOptions = 20, plugins = list("remove_button")), server = TRUE)
        coord.list(coord.new)
      }
    })

    ## Add reference genome and name to selected genomic range through a pop-up window
    # reactiveValues object for storing current data set.
    vals <- reactiveValues(data = NULL)

    dataModal <- function(failed = FALSE) {
      coord.list <- coord.list()
      modalDialog(
        textInput("region.name", "Insert name of region",
                  placeholder = 'e.g. GAPDH promoter',
        ),
        span(coord.list[length(coord.list)]),
        if (failed)
          div(tags$b("These coordinates already exist, to change the name remove the old one from the list before.", style = "color: red;")),

        footer = tagList(
          modalButton("Cancel"),
          actionButton("ok", "OK")
        )
      )
    }

    # Show modal when button is clicked.
    observeEvent(input$add, {
      showModal(dataModal())
    })

    # When OK button is pressed, attempt to load the data set. If successful,
    # remove the modal. If not show another modal, but this time with a failure
    # message.
    observeEvent(input$ok, {
      coord.list <- coord.list()
      refgenNew <- refgenNew()
      # Check that data object exists and is data frame.
      if (!is.null(input$region.name) && str_count(coord.list[grep(coord.list[length(coord.list)], coord.list)], ":") < 3){
        vals$data <- input$region.name
        coord.list[length(coord.list)] <- paste(coord.list[length(coord.list)], refgenNew, vals$data, sep=":")
        updateSelectizeInput(session = getDefaultReactiveDomain(), "select", selected = "", choices = coord.list, options = list(maxOptions = 20, plugins = list("remove_button")), server = TRUE)
        coord.list(coord.list)
        removeModal()
      } else {
        showModal(dataModal(failed = TRUE))
      }
    })


    #####----------------- REMOVE visualized coordinates from coordinates list
    ## Save coordinates to variables
    ## Chr
    chrRem <- eventReactive(input$remove, {
      print(input$chr)
    })
    ## Chr start
    chrstartRem <- eventReactive(input$remove, {
      if (input$chrstart <= 0) {print(1)} else {
        print(input$chrstart)}
    })
    ## Chr end
    chrendRem <- eventReactive(input$remove, {
       chrom.cen.df <- chrom.cen.df()
      if (input$chrend > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) { print(chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])
      } else print(input$chrend)
    })

    ## Remove coordinates to Selectize drop-down list
    ### Remove just if matching
    observeEvent(input$remove,{
      chrRem <- chrRem()
      chrstartRem <- chrstartRem()
      chrendRem <- chrendRem()
      coord.list <- coord.list()
      coord.new <- c(coord.list[coord.list != grep(paste(paste("chr", chrRem, sep=""), chrstartRem, chrendRem, sep=":"), coord.list, value = T)])
      #print(coord.new)

      updateSelectizeInput(session = getDefaultReactiveDomain(), "select", selected = "", choices = coord.new, options = list(maxOptions = 20, plugins = list("remove_button")), server = TRUE)
      coord.list(coord.new)
      #print(coord.list())
    })

    #####----------------- EXPORT updated coordinates to file
    ## Arrange coordinates to table
    output$export <- downloadHandler(
      filename = function() { "User_Defined_RegionTable.bed" },
      content = function(file) {
        coord.list <- coord.list()
        write_delim(as.data.frame(str_split_fixed(coord.list , ":", n=5)), file = file, delim = "\t", col_names = F)
      })
    ##----------------------- END OF User selected coordiates REGION TABLE

    ##----------------------- START BigWig autoscale options dialog

    # Set reactive values with bw names to be listed
    bw.items <- reactiveVal(c(config$bw.names))

    # Track number of groups and their IDs
    group.count <- reactiveVal(0)
    group.ids <- reactiveVal(character(0))

    # Initialize the individual scale to false and update it on interaction
    individual.scale.state <- reactiveVal(F)
    observeEvent(input$individual.scale, {
      individual.scale.state(input$individual.scale)
    })

    # Store final accepted settings
    user.selection <- reactiveVal(NULL)

    # --- OPEN MODAL ---
    observeEvent(input$bw.autoscale, {
      showModal(modalDialog(
        title =  tags$div("BigWig autoscale settings", style = "font-size:18px; font-weight:bold; margin-bottom:2px"),
        h6("Choose one of the options below:", style = "margin-top: 0px;"),
        tags$hr(),
        # Option 1: Checkbox
        fluidRow(
          column(width = 5, h6("1) Set individual scale"), style = "text-align:left;"),
          column(width = 7, checkboxInput("individual.scale", label = NULL, value = individual.scale.state(), width = "70%"), style = "align:left"),
        ),
        tags$hr(),
        # Option 2: Autoscale groups

        conditionalPanel(
          condition = "!input.individual.scale",  # Hide if checkbox selected
          fluidRow(column(width = 5, h6("2) Autoscale Groups")),
                   column(width = 7, uiOutput("add.group.ui"), style = "align:left;")), # add group
          uiOutput("groups.ui"), # store groups
        ),
        easyClose = TRUE,
        footer = tagList(
          modalButton("Cancel"),  # closes modal without saving
          actionButton("confirm.enter", "Enter")  # confirm choices
        )
      ))
    })

    # --- DYNAMIC UI for Add Group button ---
    output$add.group.ui <- renderUI({
      req(!isTRUE(individual.scale.state()))

      # Compute which items are still available overall
      selected.values <- unlist(lapply(group.ids(), function(id) input[[id]]))
      selected.values <- selected.values[!is.na(selected.values)]

      all.selected <- length(unique(selected.values)) >= length(bw.items())

      if (all.selected) {
        # If all items are used, disable adding new groups
        tags$span("All available items have been assigned — no more groups can be added.",
                  style = "color: #888; font-style: italic;")
      } else {
        actionButton("add.group", "+ Add", style = "font-size:80%; padding: 5px 5px; border-color:slategrey")
      }
    })


    # --- ADD GROUP ---
    observeEvent(input$add.group, {
      # Compute max number of groups allowed
      max.groups <- length(bw.items())
      # Only add a group if we haven't reached the maximum
      if (group.count() < max.groups) {
        # Uncheck individual scale when user starts adding groups
        updateCheckboxInput(session, "individual.scale", value = FALSE)
        id <- paste0("group.", group.count() + 1)
        group.count(group.count() + 1)
        group.ids(c(group.ids(), id))
      }
    })

    # --- RENDER AUTOSCALE GROUP UI ---
    output$groups.ui <- renderUI({
      req(group.ids())
      if (isTRUE(individual.scale.state())) return(NULL)
      if (length(group.ids()) == 0) return (NULL)
      # Collect all selected values across groups
      selected.values <- unlist(lapply(group.ids(), function(id) input[[id]]))
      selected.values <- selected.values[!is.na(selected.values)]

      # Each group can select from items not already chosen elsewhere,
      # plus whatever it already selected (so it doesn’t disappear)
      tagList(
        lapply(group.ids(), function(id) {
          other.selected <- unlist(lapply(setdiff(group.ids(), id), function(gid) input[[gid]]))
          other.selected <- other.selected[!is.na(other.selected)]
          remaining.choices <- setdiff(bw.items(), other.selected)

          selectizeInput(
            inputId = id,
            label = paste("Group", gsub("group.", "", id)),
            choices = remaining.choices,
            selected = input[[id]],
            multiple = TRUE,
            options = list(placeholder = "Select one or more samples...")
          )
        })
      )

    })

    # --- HANDLE "ENTER" ---
    observeEvent(input$confirm.enter, {
      if (isTRUE(individual.scale.state())) {
        user.selection(list(mode = "individual"))
      } else if (!isTRUE(individual.scale.state()) & length(group.ids()) > 0) {
        selected.groups <- lapply(group.ids(), function(id) input[[id]])
        # Remove empty or NULL groups
        selected.groups <- Filter(function(x) !is.null(x) && length(x) > 0, selected.groups)
        if (length(selected.groups) > 0) {
          names(selected.groups) <- paste0("Group ", seq_along(selected.groups))
          user.selection(list(mode = "autoscale", groups = selected.groups))
        } else {
          user.selection(NULL)
        }
      } else {
        user.selection(NULL)
      }
      removeModal()
    })

    # --- REACTIVE OUTPUT: grouped items to be used for plotgardener plotting function ---
    grouped.bw.items <- reactive({
      # If no selection yet, return NULL
      if (is.null(user.selection()) || length(user.selection()) == 0) {
        return(NULL) }
      all.items <- bw.items()
      if (user.selection()$mode == "individual") {
        # each item in its own array
        return(lapply(all.items, function(x) c(x))) }
      # autoscale mode
      selected.groups <- user.selection()$groups # list of arrays
      if (is.null(selected.groups) || length(selected.groups) == 0) {
        return(NULL) # no groups selected
      }
      grouped.items <- unlist(selected.groups)
      ungrouped.items <- setdiff(all.items, grouped.items)
      # combine groups + single-item arrays for ungrouped
      autoscale.groups <- c(selected.groups, lapply(ungrouped.items, function(x) c(x)))

      return(autoscale.groups)
    })
    ##----------------------- END BigWig autoscale options dialog

    ##------------------------ Save plot as PDF or user selected format

    # Reactive to store the chosen file format
    chosen.format <- reactiveVal(NULL)

    # Open modal to ask for format
    observeEvent(input$ask.download, {
      showModal(modalDialog(
        title = "Choose download format",
        radioButtons("file.format", "Format:",
                     choices = c("PDF" = "pdf", "SVG" = "svg", "PNG" = "png", "JPEG" = "jpg")),
        footer = tagList(
          # Message for saving status
          tags$div(id = "status", style = "font-weight:bold; color:grey; font-size:90%"),
          tags$script(HTML("Shiny.addCustomMessageHandler('savingMessage', function(message) {
                            document.getElementById('status').innerText = message.text;
                            });")),
          # Buttons
          modalButton("Close"),
          downloadButton("plot.save", "Confirm")
        )
      ))
    })

    # When user confirms, store format and trigger download
    observeEvent(input$file.format, {
      req(input$file.format)
      chosen.format(input$file.format)
      print(chosen.format())
    })

    # Actual download handler
    output$plot.save <- downloadHandler(
      filename = function() {
        paste("chr", reactiveChr(), "_",reactiveChrstart(), "-", reactiveChrend(), ".", chosen.format(), sep="")
      },
      content = function(file) {
        req(chosen.format())
        genes.hgnc <- genes.hgnc()
        fmt <- chosen.format()
        # Tell user the plot is saving
        session$sendCustomMessage("savingMessage", list(text = "Saving... please wait."))

        if (fmt == "pdf") {
          pdf(file, width = 12, height = 8 )
        } else if (fmt == "svg") {
          svglite(file, width = 12, height = 8 )
        } else if (fmt == "png") {
          png(file, width =3000, height=2300, res = 300 )
        } else if (fmt == "jpg") {
          jpeg(file, width =3000, height=2300, res = 300 )
        }
        plotgardener.shiny.function(bw.file = bw.file,
                                    hic.file = hic.file,
                                    bed.file = bed.file,
                                    bedpe.file = bedpe.file,
                                    bw.names = config$bw.names,
                                    hic.names = config$hic.names,
                                    bed.names = config$bed.names,
                                    bedpe.names = config$bedpe.names,
                                    gwas.file = gwas.file,
                                    gwas.names = config$gwas.names,
                                    cat.file = cat.file,
                                    cat.names = config$cat.names,
                                    cat.collapse = reactiveCat(),
                                    chr = reactiveChr(), #input$chr,
                                    start = reactiveChrstart(), #input$chrstart,
                                    end = reactiveChrend(), #input$chrend,
                                    bw.mode = input$bw.mode,
                                    bw.autoscale = grouped.bw.items(),
                                    expand.transcripts = reactiveTranscript(),
                                    genes.hgnc = genes.hgnc,
                                    genome = gsub( " .*", "", input$ref.genome),
                                    cytoband = Cytoband(),
                                    ideogram = reactiveIdeogram())
        dev.off()

        # Tell user the plot has been saved
        session$sendCustomMessage("savingMessage", list(text = "Saved!"))

      })
    ##------------------------ END OF Save plot as PDF

    session$onSessionEnded(function() { stopApp() })
}

# Run the app -------------------------------------------------------
shinyApp(ui = ui, server = server)
