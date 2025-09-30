
######----------------------------------------------------------- LOADING LIBRARIES
# Load shiny libraries and graphical (CRAN)
library(shiny)
library(bslib)
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

######----------------------------------------------------------- READING DATSETS FROM CONFIG FILE
Sys.setenv(R_CONFIG_ACTIVE = "default")
config_gen <- config::get(file = "GenomicViewer_config_gen.yml")
config <- config::get(file = "/data/GenomicViewer_config.yml")

## Read data
# Set a BigWig file
bw.file <- dir(paste(config$data.dir, config$bw.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$bw.ext)
# Set a bed file
bedpe.file <- dir(paste(config$data.dir, config$bedpe.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$bedpe.ext)
# Set a bedpe file
bed.file <- dir(paste(config$data.dir, config$bed.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$bed.ext)
# Set hiC data file
hic.file <- dir(paste(config$data.dir, config$hic.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$hic.ext)
# Set GWAS data file
gwas.file <- dir(paste(config$data.dir, config$gwas.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$gwas.ext)
# Categorical bed file
cat.file <- dir(paste(config$data.dir, config$cat.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$cat.file)
# Region Table file
saved.coord.path <- dir(paste(config$data.dir, config$reg.dir, sep=""), recursive = T, include.dirs = T, full.names = TRUE, pattern = config$reg.file)
saved.coord <- read_delim(saved.coord.path, "\t", col_names = F, show_col_types = F)
saved.coord <- apply(saved.coord, MARGIN = 1, function(x) paste(x, collapse = ":"))
saved.coord <- gsub(" ", "", saved.coord) # remove eventual white spaces
## Set options for bw file plotting mode:
bw.mode <- c("Profile", "Heatmap", "Profile and Heatmap")


######----------------------------------------------------------- SHINY
shiny::addResourcePath('www', '/shiny-app-GenomicViewer/www')
# Define UI -----------------------------------------------------
ui <- page_sidebar(
  title = span("", img(src = "www/GV_logo.png", height = 50, style = "margin-left:10%;" )),
  sidebar = sidebar(
    # graphics tags
    style = "background-color:#f2f0eb",
    tags$style(type='text/css',
               ".selectize-dropdown-content{font-size: 85%;}
               .selectize-input { word-wrap : break-word;}
               .selectize-input { word-break: break-word;}
               svg { font-family: 'Arial'}"
               ),
    width = 300,
    # text input to choose genomic coordinates:
    helpText("Choose the reference genome and the genomic range to be visualized, then press GO."),
      # Reference genome
    selectInput("ref.genome", "Select reference genome", c("hg19 (GRCh19 - human)", 
                                                             "hg38 (GRCh38 - human)", 
                                                             "T2T (CHM13 - human)",
                                                             "mm10 (GRCm38 - mouse)",
                                                             "mm39 (GRCm39 - mouse)"), selectize = F),
    card(tags$b("Option 1: Manually insert coordinates", style = "font-size: 90%; text-align:center"),  
      # Chr
    textInput("chr", "Choose chromosome:", value = "1"),
      # coordinates
    numericInput( 
      "chrstart", 
      "Start coordinate", 
      value = 28000000, 
      min = NA, 
      max = NA 
      ), 
    numericInput( 
      "chrend", 
      "End coordinate", 
      value = 28500000, 
      min = NA, 
      max = NA 
      )
    ), 
  
  card(tags$b("Option 2: Load saved coordinates", style = "font-size: 90%; text-align:center"),
  # List of user-defined coordinates
    selectizeInput(
     inputId = "select", 
     label = "Select from menu",
     choices = saved.coord,
     multiple = F,
     selected = ""
     ),
  
  #uiOutput("out"),
  fluidRow( 
    actionButton("add", "Add", width = "33%", style = "font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white"),
    actionButton("remove", "Remove", width = "33%", style = "font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white"),
    downloadButton("export", "Export", style = "width: 33%; font-size: 75%; font-weight: 600; padding:3px 3px; color: black; background-color: white"),
    column(width = 12, h6(tags$i("Add, remove or export coordinates to list"), style = "font-size: 80%"), style = "text-align:center")
      )
  ),
  
  # GO button
  actionButton("go", tags$b("Go")),
  
  # Download button 
  downloadButton('plot_save', "Save"),
  ),
  
  # Card
  page_fillable(
    layout_columns(
      navset_card_underline(
            title = "Selected genomic region",
            header = h6(textOutput("sel.coord"), style = "font-size:14px; padding:0px 0px;"), 
              # Panel with plot ----------------------------------------------------------------------------------
              nav_panel("Plot", class = "gap-2 p-0 border-0 align-items-top",
                        svgPanZoomOutput(outputId = "res", width = "auto", height = "900px") %>% withSpinner(color = "salmon", type = 6, size = 0.5),
                        imageOutput("plot.test", width = "auto", height = "10px", inline=T) %>% withSpinner(color = "salmon", type = 6, size = 0.5),
                        plotOutput("plot", brush = brushOpts(id = "plot_brush", direction = c("x")), inline=T), 
                        fluidRow(column(width = 2, h6(tags$b("Zoom-out:")), style = "text-align:right"), 
                        column(width = 1, actionButton("z2out", "2x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z5out", "5x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z10out", "10x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                        column(width = 2, h6(tags$b("Zoom-in:")), style = "padding: 3px 5px; text-align:right"),
                        column(width = 1,actionButton("z2in", "2x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z5in", "5x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z10in", "10x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px")
              )
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
                fluidRow(plotOutput("upset", height = 300) %>% withSpinner(), verbatimTextOutput('warn.message2')),
                # GO button upset
                actionButton("run.stat2", "Run", width = "25%"),
                # print piechart with peaks annotation
                fluidRow(h6(tags$b("Peaks Annotation")),tags$hr(), plotOutput("annotation", height = 350)  %>% withSpinner(), verbatimTextOutput('warn.message3')),
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
                      plotOutput("chr.plot", click = clickOpts(id = "chr.click", clip = T), hover = "chr.hover"),
                      verbatimTextOutput("chr.info"),
                      span(tags$b("Advanced Options:"), style = "text-align: center;"),
                      # Search by gene
                      selectizeInput('gene.search', 'Search by gene', selected = "", choices = character(0)),
                      textOutput('sel.gene'),
                      # Select mode for bigwig plotting
                      selectInput('bw.mode', 'Select bigWig plots mode', bw.mode, selectize=FALSE),
                      # Select mode for categories plotting
                      selectInput('cat.mode', 'Select categories to expand', choices = config$cat.names, multiple = T),
                      # Expand transcript track option
                      checkboxInput("checkbox", "Expand transcripts", FALSE))
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
  genes.hgnc.path <- paste(config_gen$genes.hgnc.dir, "/", gsub( " .*", "", input$ref.genome), "_gene_symbol_cleaned.bed", sep="")
  genes.hgnc <- read_delim(genes.hgnc.path, "\t", col_names = T, show_col_types = F)
  })
  
  ### For chromosomes plotting
  chrom.cen.df <- eventReactive(input$ref.genome, {
  chrom.cen.path <- paste(config_gen$chrom.cen.dir, "/chrom_centromeres_", gsub( " .*", "", input$ref.genome), ".txt", sep="")
  chrom.cen.df <- read_delim(chrom.cen.path, "\t", col_names = T, show_col_types = F)
  })
  
  ### For cytoband
  Cytoband <- eventReactive(input$ref.genome, {
    ref.genome <- gsub( " .*", "", input$ref.genome)
    if (ref.genome %in% c("hg19", "hg38", "mm10")){
      cytoband <- NULL
    } else if (ref.genome == "T2T"){
      cytoband <- read_delim(paste(config_gen$chrom.cen.dir, "/chm13v2.0_cytobands_allchrs.bed", sep=""), delim = "\t", col_names = F)
      colnames(cytoband) <- c("seqnames", "start", "end", "name", "gieStain")
      return(cytoband)
    } else if (ref.genome == "mm39"){
      cytoband <- read_delim(paste(config_gen$chrom.cen.dir, "/cytoBand_GRCm39.txt", sep=""), delim = "\t", col_names = F)
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
    if (input$chrstart <= 0) {print(1)} else {
    print(input$chrstart)}
  })
  ## Chr end
  reactiveChrend <- eventReactive(input$go, {
    chrom.cen.df <- chrom.cen.df()
    if (input$chrend > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) { print(chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])
      } else print(input$chrend)
  })
  ## Categories to expand
  reactiveCat <- reactive({
    exp.cat <- c(!config$cat.names %in% input$cat.mode)
  })

  
  ########################## CARD PLOT
  ##---------------------- Output selected coordinates text:
  output$sel.coord <- renderText({paste("chr", reactiveChr(), ": ", reactiveChrstart(), "-", reactiveChrend(), sep="")})
  ##---------------------- Output genomic view plot:
  
    tracks <- reactive({
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
                                                                          expand.transcripts = reactiveTranscript(),
                                                                          genes.hgnc = genes.hgnc,
                                                                          genome = gsub( " .*", "", input$ref.genome),
                                                                          cytoband = Cytoband())
    # } else {return(NULL)}
      
    })
  
  output$res <- renderSvgPanZoom({
    #req(!is.null(tracks()))
    svgPanZoom(svglite:::inlineSVG(tracks()), 
               panEnabled = T, controlIconsEnabled = T, viewBox = T, width = "auto", height = "900px") #width = "auto", height = "auto",
    
  })
  
  image <- reactive({
    genes.hgnc <- genes.hgnc()
    req(sum((file.size(c(bw.file, bedpe.file, bed.file, hic.file, gwas.file, cat.file))))/2^30 > 2 & (reactiveChrend() - reactiveChrstart()) > 5e+05)
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
                                expand.transcripts = reactiveTranscript(),
                                genes.hgnc = genes.hgnc,
                                genome = gsub( " .*", "", input$ref.genome),
                                cytoband = Cytoband())
    dev.off()
    list(src = outfile,
         alt = "genomic viewer image")
    #} else {return(NULL)}
  })
  
  output$plot.test <- renderImage({
#    req(!is.null(image()))
    image()
  }, deleteFile = F)
  
 

  ##-------------------- Output zooming region plot:
  
  output$plot <- renderPlot({
    x.ext <- (input$chrend - input$chrstart)*25/100
   p <- ggplot() + 
      geom_rect(aes(xmin = input$chrstart - x.ext, xmax = input$chrend + x.ext, ymin = 10, ymax = 11), fill = "grey") +
      geom_rect(aes(xmin = input$chrstart, xmax = input$chrend, ymin = 10, ymax = 11), fill = "salmon", colour = "darkred") +
     xlab("Select a region to ZOOM") +
      theme_void() +
      theme(axis.text.x = element_text(size = 12),
            axis.ticks.x = element_line(),
            legend.position = "none",
            axis.title.x = element_text(face = "bold", size=15),
            plot.margin = unit(c(0,0,0.25,0), "cm")) 
    p
  },
  width = "auto",
  height = 50
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
        filename = function(){paste0(config$cat.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".cat")},
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
        filename = function(){paste0(config$gwas.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".gwas")},
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
  vals <- reactiveValues(bed.file=NULL, bedpe.file=NULL, chr = "1", start = 2800000, end = 2850000)
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
    vals2 <- reactiveValues(bed.file=NULL, bedpe.file=NULL, chr = "1", start = 2800000, end = 2850000)
    
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
                                       bedpe.file = vals$bedpe.file, 
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
    }, res = 100)
    
    ## For circos plot
    vals6 <- reactiveValues(bedpe.file=NULL, chr = "1", start = 2800000, end = 2850000)
    
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
    vals4 <- reactiveValues(cat.file=NULL, chr = "1", start = 2800000, end = 2850000)
    
    observeEvent(input$run.stat4, {
      vals4$cat.file <- cat.file[which(file.size(cat.file) <= 400e+06)]
      vals4$chr <-  input$chr
      vals4$start <- input$chrstart
      vals4$end <- input$chrend
      # Specifiy if data not plotted in warning message
      large.data <- c(config$cat.names[which(file.size(cat.file) > 400e+06)])
      if(!isEmpty(large.data)){
        output$warn.message4 <- renderText({paste(large.data,"data larger than", ceiling(400e+06/2^20), "Mb not plotted",  collapse = " ")}) ### not working sistemare
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
    vals5 <- reactiveValues(gwas.file=NULL, chr = "1", start = 2800000, end = 2850000)
    
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
                              sign.p = 5e-10,
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
      ggchicklet:::geom_rrect(aes(xmin = order - 0.25,
                                  xmax = order + 0.25,
                                  ymin = cen.start,
                                  ymax = chr.len,
                                  fill = chr)) +
      ggchicklet:::geom_rrect(aes(xmin = order - 0.25,
                                  xmax = order + 0.25,
                                  ymin = 0,
                                  ymax = cen.end,
                                  fill = chr)) +
      scale_x_continuous(breaks = c(1:length(chrom.cen.df$chr)), labels = factor(chrom.cen.df$chr, levels = chrom.cen.df$chr)) +
      theme_void() +
      theme(legend.position = "none",
            axis.ticks.x = element_line(linewidth = 2, linetype = 2),
            axis.text.x = element_text(angle = 90, face = "bold"))
    
  }, height = 150, width = "auto")
    
    ## Hover output

  output$chr.info <- renderText({
    chrom.cen.df <- chrom.cen.df()
    if(!is.null(input$chr.hover)){
      hover=input$chr.hover
      paste0(chrom.cen.df$chr[round(as.numeric(hover[1],0))], ": click to select")
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
    updateSelectizeInput(session = getDefaultReactiveDomain(), "gene.search", selected = "", choices = genes.hgnc$gene_symbol, options = list(maxOptions = 12), server = TRUE)
  })
  
  output$sel.gene <- renderText({input$gene.search})

  observeEvent(gene.names(),{
    if (!input$gene.search == ""){
    genes.hgnc <- genes.hgnc()
    updateTextInput(session = getDefaultReactiveDomain(), "chr", value = genes.hgnc$chromosome_name[which(genes.hgnc$gene_symbol == input$gene.search)])
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = genes.hgnc$start_position[which(genes.hgnc$gene_symbol == input$gene.search)])
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = genes.hgnc$end_position[which(genes.hgnc$gene_symbol == input$gene.search)])
    }
  })
  ##------------------------ END OF Search by gene
  
  ##------------------------ Expand transcripts checkbox
  reactiveTranscript <- eventReactive(input$checkbox, {
    print(input$checkbox)
  })
  ##------------------------ END OF Expand transcripts checkbox
  
  ##------------------------ Update chr start end upon click on chr plot
    observeEvent(input$chr.click, {
      chrom.cen.df <- chrom.cen.df()
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x2 <- input$chr.click
    updateTextInput(session = getDefaultReactiveDomain(), "chr", value = gsub("chr", "", chrom.cen.df$chr[x2$x]))
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = 1)
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == chrom.cen.df$chr[x2$x])])
  })
    ##----------------------- END OF Update chr start end upon click on chr plot
  
    ##----------------------- User selected coordiates REGION TABLE
    coord <- reactive({
      if (!is.null(saved.coord)){
        coord <- saved.coord
      }
    })
    # if there is a coord file update the list from whcih the used can select
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
    coord.list <- reactiveVal(value = saved.coord)
    #####----------------- ADD visualized coordinates to coordinates list
    ## Save coordinates to variables
    ## Chr
    chrNew <- eventReactive(input$add, {
      print(input$chr)
    })
    ## Chr start
    chrstartNew <- eventReactive(input$add, {
      if (input$chrstart <= 0) {print(1)} else {
        print(input$chrstart)}
    })
    ## Chr end
    chrendNew <- eventReactive(input$add, {
       chrom.cen.df <- chrom.cen.df() #UNCOMMENT THIS LINE IN THE REAL CODE
      if (input$chrend > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) { print(chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))])
      } else print(input$chrend)
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
        #print(coord.list())
      }
    })
    
    ## Add name to selected genomic range through a pop-up window
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
      # Check that data object exists and is data frame.
      if (!is.null(input$region.name) && str_count(coord.list[grep(coord.list[length(coord.list)], coord.list)], ":") < 3){ 
        vals$data <- input$region.name
        coord.list[length(coord.list)] <- paste(coord.list[length(coord.list)], vals$data, sep=":")
        updateSelectizeInput(session = getDefaultReactiveDomain(), "select", selected = "", choices = coord.list, options = list(maxOptions = 20, plugins = list("remove_button")), server = TRUE)
        coord.list(coord.list)
        removeModal()
      } else {
        showModal(dataModal(failed = TRUE))
      }
    })
    
    
    #####----------------- REMOVE visualized coordinates to coordinates list
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
       chrom.cen.df <- chrom.cen.df() #UNCOMMENT THIS LINE IN THE REAL CODE
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
    
    #####----------------- EXPORT updated coordinates coordinates to file
    ## Arrange coordinates to table  
    output$export <- downloadHandler(
      filename = function() { "User_Defined_RegionTable.bed" },
      content = function(file) {
        coord.list <- coord.list()
        write_delim(as.data.frame(str_split_fixed(coord.list , ":", n=4)), file = file, delim = "\t", col_names = F)
      })
    ##----------------------- END OF User selected coordiates REGION TABLE
  
    ##------------------------ Save plot as PDF
    
    output$plot_save <- downloadHandler(
      filename = function() { "output.pdf" },
      content = function(file) {
      genes.hgnc <- genes.hgnc()
      pdf(file, width = 10, height = 8 )
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
                                    expand.transcripts = reactiveTranscript(),
                                    genes.hgnc = genes.hgnc,
                                    genome = gsub( " .*", "", input$ref.genome),
                                    cytoband = Cytoband())
         dev.off()
      
      })
    ##------------------------ END OF Save plot as PDF
    
    session$onSessionEnded(function() { stopApp() })
}

# Run the app -------------------------------------------------------
shinyApp(ui = ui, server = server)
