
######----------------------------------------------------------- LOADING LIBRARIES
# Load shiny libraries and graphical
library(shiny)
library(bslib)
library(svglite)
library(svgPanZoom)
library(paletteer)
# Load server libraries
library(plotgardener)
library(org.Hs.eg.db)
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
library(AnnotationHub)
library(ggplot2)

# Source script
#setwd("C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps")
source("plotgardener_shiny_wzoomYML_hover.r")


######----------------------------------------------------------- READING DATSETS FROM CONFIG FILE
Sys.setenv(R_CONFIG_ACTIVE = "default")
config <- config::get(file = "Shiny_wzoom_config_hover.yml")

## Read data
# Set a BigWig file
bw.file <- dir(paste(config$data.dir, config$bw.dir, sep=""), full.names = TRUE, pattern = config$bw.ext)
# Set a bed file
bedpe.file <- dir(paste(config$data.dir, config$bedpe.dir, sep=""), full.names = TRUE, pattern = config$bedpe.ext)
# Set a bedpe file
bed.file <- dir(paste(config$data.dir, config$bed.dir, sep=""), full.names = TRUE, pattern = config$bed.ext)
# Set hiC data file
hic.file <- dir(paste(config$data.dir, config$hic.dir, sep=""), full.names = TRUE, pattern = config$hic.ext)

## Seto options for bw file plotting mode:
bw.mode <- c("Profile", "Heatmap", "Profile and Heatmap")

######----------------------------------------------------------- SHINY
# Define UI ----
ui <- page_sidebar(
  title = "Genomic viewer",
  sidebar = sidebar(
    # text input to choose genomic coordinates:
    helpText("Choose the genomic range to be visualized."),
      # Chr
    textInput("chr", "Choose chromosome:", value = "1"),
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
      value = 28500000, 
      min = 2, 
      max = NA 
    ), 

    
    # Select mode for bigwig plotting
    selectInput('bw.mode', 'Select bigWig plots mode', bw.mode, selectize=FALSE),
    
  # Submit button
    submitButton("Submit")
   ),
  
  # Card
   card(card_header(
     class = "bg-dark",
     "Selected genomic region"),
     
   card_body(class = "gap-2 p-3 border-0 align-items-center",
             svgPanZoomOutput(outputId = "res"),
             plotOutput("plot", click = "plot_click", brush = "plot_brush", inline = T, width = "600px", height = "10%"), 
             verbatimTextOutput("click_info"))
  
  )
  )

# Define server logic ----
server <- function(input, output){
  # Output genomic view plot.
  output$res <- renderSvgPanZoom({
    svgPanZoom(svglite:::inlineSVG(plotgardener.shiny.function(bw.file = bw.file, 
                                                                hic.file = hic.file, 
                                                                bed.file = bed.file, 
                                                                bedpe.file = bedpe.file,
                                                                bw.names = config$bw.names,
                                                                hic.names = config$hic.names,
                                                                bed.names = config$bed.names,
                                                                bedpe.names = config$bedpe.names,
                                                                chr = input$chr, 
                                                                start = input$chrstart, 
                                                                end = input$chrend,
                                                                bw.mode = input$bw.mode)
    ), panEnabled = F, width = "600px", height = "600px", controlIconsEnabled = T)
    
  })

  output$plot <- renderPlot({
   p <- ggplot() + 
      geom_rect(aes(xmin = input$chrstart, xmax = input$chrend, ymin = 10, ymax = 11, fill = "lightblue")) +
      theme_void() +
      theme(axis.text.x = element_text(),
            axis.ticks.x = element_line(),
            legend.position = "none")
    p
  },
  width = 800,
  height = 25) 

  output$click_info <- renderText({
    xy_range_str <- function(e) {
      if(is.null(e)) return("NULL\n")
      paste0("From=", round(e$xmin, 0), " To=", round(e$xmax, 0))
    }
    
    paste0(
      "Genomic range: ", xy_range_str(input$plot_brush)
    )
  })
  
  ## Update chr start end upon click
  observeEvent(input$plot_brush, {
    # We'll use the input$controller variable multiple times, so save it as x
    # for convenience.
    x <- input$plot_brush
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = round(x$xmin, 0))
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = round(x$xmax, 0))
  })
}

# Run the app ----
shinyApp(ui = ui, server = server)
