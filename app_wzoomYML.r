
######----------------------------------------------------------- LOADING LIBRARIES
# Load shiny libraries and graphical
library(shiny)
library(bslib)
library(svglite)
library(svgPanZoom)
# Load server libraries
library(plotgardener)
library(org.Hs.eg.db)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(AnnotationHub)

# Source script
setwd("C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML")
source("plotgardener_shiny_wzoomYML.r")


######----------------------------------------------------------- READING DATSETS FROM CONFIG FILE
Sys.setenv(R_CONFIG_ACTIVE = "default")
config <- config::get(file = "C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/Shiny_wzoom_config.yml")

# Read data
# Select a BigWig file
bw.file <- dir(paste(config$data.dir, config$bw.dir, sep=""), full.names = TRUE, pattern = config$bw.ext)

# Select a bed or bedpe file
bedpe.file <- dir(paste(config$data.dir, config$bedpe.dir, sep=""), full.names = TRUE, pattern = config$bedpe.ext)

bed.file <- dir(paste(config$data.dir, config$bed.dir, sep=""), full.names = TRUE, pattern = config$bed.ext)

# Select hiC data file
hic.file <- dir(paste(config$data.dir, config$hic.dir, sep=""), full.names = TRUE, pattern = config$hic.ext)

######----------------------------------------------------------- SHINY
# Define UI ----
ui <- page_sidebar(
  title = "Genomic viewer",
  sidebar = sidebar(
    # Text introduction
   #   helpText("Upload here the genomic tracks to be visualized."),
     # File input button
      #fileInput("bed", label = "Upload .bed file"),
      #fileInput("bw", label = "Upload .bw file"),
     # fileInput("bedpe", label = "Upload .bedpe file"),
     #fileInput("hic", label = "Upload .hic file"),

    # text input to choose genomic coordinates:
    helpText("Choose the genomic range to be visualized."),
      # Chr
    textInput("chr", "Choose chromosome:", value = "1",),
      # coordinates
    numericInput( 
      "chrstart", 
      "Start coordinate", 
      value = 28000000, 
      min = 1, 
      max = NA 
    ), 
    numericInput( 
      "chrend", 
      "End coordinate", 
      value = 30300000, 
      min = 2, 
      max = NA 
    ), 
  # Submit button
    submitButton("Submit"),
   ),
   card( card_header(
     class = "bg-dark",
     "Selected genomic region"
   ), bootstrapPage(
     svgPanZoomOutput(outputId = "res")))
  )

# Define server logic ----
server <- function(input, output){

  output$res <- renderSvgPanZoom({
    svgPanZoom( svglite:::inlineSVG(plotgardener.shiny.function(bw.file = bw.file, hic.file = hic.file, bed.file = bed.file, bedpe.file = bedpe.file, chr = input$chr, start = input$chrstart, end = input$chrend)
    ))
    
  })
}

# Run the app ----
shinyApp(ui = ui, server = server)
