
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
# for chromosomes plot
library(ggchicklet)


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
### For chromosomes plotting
chrom.cen.df <- read.table(config$chrom.cen, header = T, sep="\t")

## Set options for bw file plotting mode:
bw.mode <- c("Profile", "Heatmap", "Profile and Heatmap")

######----------------------------------------------------------- SHINY
# Define UI -----------------------------------------------------
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
    
  # GO button
  actionButton("go", "Go")
   ),
  
  # Card
  page_fillable(
    layout_columns(
       card(card_header(
            class = "bg-dark",
            "Selected genomic region"),
            
              card_body(class = "gap-2 p-3 border-0 align-items-top",
                        svgPanZoomOutput(outputId = "res"),
                        plotOutput("plot", brush = brushOpts(id = "plot_brush", direction = c("x")), inline=T), 
                        verbatimTextOutput("click_info")
                        )
                        
              ),
       card(card_header("Choose chromosome"),
            card_body(#class = "border-0 gap-1 align-items-bottom",
                      plotOutput("chr.plot", click = clickOpts(id = "chr.click", clip = F), hover = "chr.hover"),
                      verbatimTextOutput("chr.info"))
                ),
       col_widths = c(9, 3)
              )

              )
   

)

# Define SERVER logic ---------------------------------------------------
server <- function(input, output, session){
  
  ##---------------------- Establish reactive events
    ## Chr
  reactiveChr <- eventReactive(input$go, {
    print(input$chr)
  })
    ## Chr start
  reactiveChrstart <- eventReactive(input$go, {
    print(input$chrstart)
  })
  ## Chr end
  reactiveChrend <- eventReactive(input$go, {
    print(input$chrend)
  })
  
  
  ##---------------------- Output genomic view plot:
  
  output$res <- renderSvgPanZoom({
    svgPanZoom(svglite:::inlineSVG(plotgardener.shiny.function(bw.file = bw.file, 
                                                                hic.file = hic.file, 
                                                                bed.file = bed.file, 
                                                                bedpe.file = bedpe.file,
                                                                bw.names = config$bw.names,
                                                                hic.names = config$hic.names,
                                                                bed.names = config$bed.names,
                                                                bedpe.names = config$bedpe.names,
                                                                chr = reactiveChr(), #input$chr, 
                                                                start = reactiveChrstart(), #input$chrstart, 
                                                                end = reactiveChrend(), #input$chrend,
                                                                bw.mode = input$bw.mode)
    ), panEnabled = F, width = "auto", height = "auto", controlIconsEnabled = T)
    
  })

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

  ##--------------------- Output_click info deleted because by resetting the brush with every session it will not output
 # output$click_info <- renderText({
 #   xy_range_str <- function(e) {
 #     if(is.null(e)) return("NULL\n")
  #    paste0("From=", round(e$xmin, 0), " To=", round(e$xmax, 0))
  #  }
#    paste0("Genomic range: ", xy_range_str(input$plot_brush))
 # })
  
  ##-------------------- Update chr start end upon click on zoomed range
  observeEvent(input$plot_brush, {
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x <- input$plot_brush
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = round(x$xmin, 0))
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = round(x$xmax, 0))
    
    session$resetBrush("plot_brush")
  })
  
  ##--------------------- Chromosome plot
    ## Plot
  output$chr.plot <- renderPlot({
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
      scale_x_continuous(breaks = c(1:24), labels = factor(chrom.cen.df$chr, levels = chrom.cen.df$chr)) +
      theme_void() +
      theme(legend.position = "none",
            axis.ticks.x = element_line(size = 2, linetype = 2),
            axis.text.x = element_text(angle = 90, face = "bold"))
    
  }, height = 150, width = "auto")
    
    ## Hover output

  output$chr.info <- renderText({
    if(!is.null(input$chr.hover)){
      hover=input$chr.hover
      paste0(chrom.cen.df$chr[round(as.numeric(hover[1],0))], ": click to select")
    }
    
  })
  
  ##------------------------ Update chr start end upon click on zoomed range
    observeEvent(input$chr.click, {
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x2 <- input$chr.click
    
    updateTextInput(session = getDefaultReactiveDomain(), "chr", value = gsub("chr", "", chrom.cen.df$chr[x2$x]))
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = 1)
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == chrom.cen.df$chr[x2$x])])
  })
  
  
}

# Run the app -------------------------------------------------------
shinyApp(ui = ui, server = server)
