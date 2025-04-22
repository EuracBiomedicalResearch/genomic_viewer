
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
library(ChIPpeakAnno)
library(rtracklayer)
library(spiky)
library(ComplexUpset)
library(dplyr)
library(ggpubr)
# for chromosomes plot
library(ggchicklet)


# Source script
#setwd("C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps")
source("plotgardener_shiny_wzoomYML_hover.r")
source("shiny_read_table_function.r")
source("basic_statistics_genome_tracks_function.r")


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
# Set GWAS data file
gwas.file <- dir(paste(config$data.dir, config$gwas.dir, sep=""), full.names = TRUE, pattern = config$gwas.ext)
### For chromosomes plotting
chrom.cen.df <- read.table(config$chrom.cen, header = T, sep="\t")
# Categorical bed file
cat.file <- dir(full.names = TRUE, pattern = config$cat.file)

## Set options for bw file plotting mode:
bw.mode <- c("Profile", "Heatmap", "Profile and Heatmap")

######----------------------------------------------------------- SHINY
# Define UI -----------------------------------------------------
ui <- page_sidebar(
  title = "Genomic viewer",
  sidebar = sidebar(
    # text input to choose genomic coordinates:
    helpText("Choose the genomic range to be visualized, then press GO."),
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
  actionButton("go", "Go"),
  
  # Download button 
  downloadButton('plot_save', "Save")
   ),
  
  # Card
  page_fillable(
    layout_columns(
      navset_card_underline(
            title = "Selected genomic region",
              # Panel with plot ----------------------------------------------------------------------------------
              nav_panel("Plot", class = "gap-2 p-3 border-0 align-items-top",
                        svgPanZoomOutput(outputId = "res"),
                        plotOutput("plot", brush = brushOpts(id = "plot_brush", direction = c("x")), inline=T), 
                        verbatimTextOutput("click_info"),
                        fluidRow(column(width = 2, h6(tags$b("Zoom-out:")), style = "text-align:right"), 
                        column(width = 1, actionButton("z1out", "1x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z5out", "5x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z10out", "10x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"),
                        column(width = 2, h6(tags$b("Zoom-in:")), style = "padding: 3px 5px; text-align:right"),
                        column(width = 1,actionButton("z1in", "1x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z5in", "5x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px"), 
                        column(width = 1,actionButton("z10in", "10x", width = "70%", style = "font-size: 75%; font-weight: 800; padding:3px 5px; color: black; background-color: lightgrey"), style = "padding: 3px 5px")
              )
                        ),
              # Panel with Table of data -------------------------------------------------------------------------
              nav_panel("Data", class = "gap-2 p-3 border-0 align-items-top",
                      # print table preview and download button: bed
                      uiOutput("view_bed"),
                      uiOutput("bed_save"),
                      # print table preview and download button: bedpe
                      uiOutput("view_bedpe"),
                      uiOutput("bedpe_save"),
                      # print table preview and download button: gwas
                      uiOutput("view_gwas"),
                      uiOutput("gwas_save")
                        ),
               # Panel with Basic Statistics of data ------------------------------------------------------------
              nav_panel("Stats", class = "gap-2 p-3 border-0 align-items-top",
                # print plots of peaks numbers
                fluidRow(h6(tags$b("Peak counts")), tags$hr(), column(width = 6, plotOutput("peak.nr", height = 200)),
                column(width = 6, plotOutput("arches.nr", height = 200))),
                # print upset plot for peaks intersections
                fluidRow(plotOutput("upset", height = 300)),
                # print piechart with peaks annotation
                fluidRow(h6(tags$b("Peaks Annotation")),tags$hr(), plotOutput("annotation", height = 200)),
                  )),
       card(card_header("Choose chromosome"),
            card_body(#class = "border-0 gap-1 align-items-bottom",
                      plotOutput("chr.plot", click = clickOpts(id = "chr.click", clip = F), hover = "chr.hover"),
                      verbatimTextOutput("chr.info"),
                      # Select mode for bigwig plotting
                      selectInput('cat.mode', 'Select categories to expand', choices = config$cat.names, multiple = T))
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
  ## Categories to expand
  reactiveCat <- reactive({
    exp.cat <- c(!config$cat.names %in% input$cat.mode)
  })

  
  ########################## CARD PLOT
  ##---------------------- Output genomic view plot:
  
  
    tracks <- reactive({
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
                                                                          bw.mode = input$bw.mode)
    
     
    })
  
  output$res <- renderSvgPanZoom({
    svgPanZoom(svglite:::inlineSVG(tracks()), 
               panEnabled = F, width = "auto", height = "auto", controlIconsEnabled = T)
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
  
  ##-------------------- Zooming when click on zoom buttons:
  ########## ZOOM-OUT
   ## Zoom out 1x
   observe({
      zoom <- round((input$chrend - input$chrstart)/2, 0)
      s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart - zoom)
      e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend + zoom)
      # Modify if values exceed chr size
      if (input$chrstart - zoom <= 0){ 
        s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
      if ( input$chrend + zoom > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){ 
        e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) }
      s
      e }) %>%  bindEvent(input$z1out)
   ## Zoom out 5x
   observe({
     zoom <- round(((input$chrend - input$chrstart)/2)*5, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend + zoom)
     # Modify if values exceed chr size
     if (input$chrstart - zoom <= 0){ 
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
     if ( input$chrend + zoom > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){ 
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) }
     s
     e }) %>%  bindEvent(input$z5out)
   ## Zoom out 10x
   observe({
     zoom <- round(((input$chrend - input$chrstart)/2)*10, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart - zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend + zoom)
     # Modify if values exceed chr size
     if (input$chrstart - zoom <= 0){ 
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = 1) }
     if ( input$chrend + zoom > chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]){ 
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == paste("chr", input$chr, sep=""))]) }
     s
     e }) %>%  bindEvent(input$z10out)
   ########## ZOOM-IN
   ## Zoom out 1x
   observe({
     zoom <- round((input$chrend - input$chrstart)/2, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart + zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend - zoom)
     # Modify if values exceed chr size
     if ((input$chrend - input$chrstart) <= 500){ 
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart) 
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }
     s
     e }) %>%  bindEvent(input$z1in)
   ## Zoom out 5x
   observe({
     zoom <- round(((input$chrend - input$chrstart)/2)*5, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart + zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend - zoom)
     # Modify if values exceed chr size
     if ((input$chrend - input$chrstart) <= 500){ 
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart) 
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }
     s
     e }) %>%  bindEvent(input$z5in)
   ## Zoom out 10x
   observe({
     zoom <- round(((input$chrend - input$chrstart)/2)*10, 0)
     s <- updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart + zoom)
     e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrend - zoom)
     # Modify if values of chr size is too low
     if ((input$chrend - input$chrstart) <= 500){ 
       s <-  updateNumericInput(getDefaultReactiveDomain(), "chrstart", value = input$chrstart) 
       e <- updateNumericInput(getDefaultReactiveDomain(), "chrend", value = input$chrstart + 500) }
     s
     e }) %>%  bindEvent(input$z10in)


  
  ##-------------------- Update chr start end upon click on zoomed range
  observeEvent(input$plot_brush, {
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x <- input$plot_brush
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = round(x$xmin, 0))
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = round(x$xmax, 0))
    
    session$resetBrush("plot_brush")
  })
  
  
  ########################## CARD DATA
  ######################################################## PLOT TAB
  datasetTables <- reactive({
                data.table <- shiny_read_table_function(bed.file = bed.file,
                                         bedpe.file = bedpe.file,
                                         gwas.file = gwas.file,
                                         chr = reactiveChr(),
                                         start = reactiveChrstart(),
                                           end = reactiveChrend())
                
                data.table
    

  })
  
  ######################################################## DATA TAB
  ###### Bed file table view
  
  # Rendering tables dependent on user input.
  observeEvent(length(bed.file), {
    lapply(1:length(bed.file), function(i) {
      output[[paste0('bed', i)]] <- renderTable({
        head(datasetTables()[[1]][[i]], n = 15)
      }, caption = config$bed.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })
  })
  
  # Rendering UI and outputtign tables dependent on user input.
  output$view_bed <- renderUI({
    lapply(1:length(bed.file), function(i) {
      uiOutput(paste0('bed', i))
      })
  })
  
  
  # Download peaks
  observeEvent(length(bed.file),{
    lapply(1:length(bed.file), function(i) {
      output[[paste0("downloadBed", i)]] <- downloadHandler(
        filename = function(){paste0(config$bed.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".bed")},
        content = function(file){
          write.table(datasetTables()[[1]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })
  
  output$bed_save <- renderUI({
    lapply(1:length(bed.file), function(i) {
      downloadButton(paste0("downloadBed", i), paste0("Download ", config$bed.names[i]))
    })
  })
  
        
  
  ###### Bedpe file table view
  
  # Rendering tables dependent on user input.
  observeEvent(length(bedpe.file), {
    lapply(1:length(bedpe.file), function(i) {
      output[[paste0('bedpe', i)]] <- renderTable({
        head(datasetTables()[[2]][[i]], n = 15)
      }, caption = config$bedpe.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })
  })
  
  # Rendering UI and outputting tables dependent on user input.
  output$view_bedpe <- renderUI({
    lapply(1:length(bedpe.file), function(i) {
      uiOutput(paste0('bedpe', i))
    })
  })
  
  
  # Download arches
  observeEvent(length(bedpe.file),{
    lapply(1:length(bedpe.file), function(i) {
      output[[paste0("downloadBedpe", i)]] <- downloadHandler(
        filename = function(){paste0(config$bedpe.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".bedpe")},
        content = function(file){
          write.table(datasetTables()[[2]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })
  
  output$bedpe_save <- renderUI({
    lapply(1:length(bedpe.file), function(i) {
      downloadButton(paste0("downloadBedpe", i), paste0("Download ", config$bedpe.names[i]))
    })
  })
  
  ###### GWAS file table view
  
  # Rendering tables dependent on user input.
  observeEvent(length(gwas.file), {
    lapply(1:length(gwas.file), function(i) {
      output[[paste0('gwas', i)]] <- renderTable({
        head(datasetTables()[[3]][[i]], n = 15)
      }, caption = config$gwas.names[i],
      caption.placement = getOption("xtable.caption.placement", "top"))
    })
  })
  
  # Rendering UI and outputting tables dependent on user input.
  output$view_gwas <- renderUI({
    lapply(1:length(gwas.file), function(i) {
      uiOutput(paste0('gwas', i))
    })
  })
  
  
  # Download GWAS
  observeEvent(length(gwas.file),{
    lapply(1:length(gwas.file), function(i) {
      output[[paste0("downloadgwas", i)]] <- downloadHandler(
        filename = function(){paste0(config$gwas.names[i],"_chr", reactiveChr(), "_", reactiveChrstart(), "-", reactiveChrend(),  ".gwas")},
        content = function(file){
          write.table(datasetTables()[[3]][[i]], file, row.names = F, quote = F, sep = "\t")
        })
    })
  })
  
  output$gwas_save <- renderUI({
    lapply(1:length(gwas.file), function(i) {
      downloadButton(paste0("downloadgwas", i), paste0("Download ", config$gwas.names[i]))
    })
  })
  
  ######################################################## STATS TAB
  ## For bed files
    output$peak.nr <- renderPlot({
      basic_statistics_genome_tracks(bed.file = bed.file, 
                                     bed.names = config$bed.names,
                                     chr = reactiveChr(),  
                                     start = reactiveChrstart(), 
                                     end = reactiveChrend(),
                                     filetype = "bed")
    })
  ## For bedpe files
    output$arches.nr <- renderPlot({
      basic_statistics_genome_tracks(bed.file = bedpe.file, 
                                   bed.names = config$bedpe.names,
                                   chr = reactiveChr(),  
                                   start = reactiveChrstart(), 
                                   end = reactiveChrend(),
                                   filetype = "bedpe")
    })
  ## For upset plot
    output$upset <- renderPlot({
      peaks_intersection_venn_function(bed.file = bed.file, 
                                       bed.names = config$bed.names, 
                                       bedpe.file = bedpe.file, 
                                       bedpe.names = config$bedpe.names, 
                                       chr = reactiveChr(), 
                                       start = reactiveChrstart(), 
                                       end = reactiveChrend())
    })
  ## For annotation plot
    output$annotation <- renderPlot({
      peaks.annotation.function(bed.file = bed.file, 
                                       bed.names = config$bed.names)
    })

  
  
  ##--------------------- Chromosome plot and additional options
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
  
    ## Category tracks expand/collapse
  
  
  ##------------------------ Update chr start end upon click on zoomed range
    observeEvent(input$chr.click, {
    # We'll use the input$controller variable multiple times, so save it as x for convenience.
    x2 <- input$chr.click
    
    updateTextInput(session = getDefaultReactiveDomain(), "chr", value = gsub("chr", "", chrom.cen.df$chr[x2$x]))
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrstart", value = 1)
    
    updateNumericInput(session = getDefaultReactiveDomain(), "chrend", value = chrom.cen.df$chr.len[which(chrom.cen.df$chr == chrom.cen.df$chr[x2$x])])
  })
  
  
    ##------------------------ Save plot as PDF
    
    output$plot_save <- downloadHandler(
      filename = function() { "output.pdf" },
      content = function(file) {
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
                                    bw.mode = input$bw.mode)
         dev.off()
      
      })
}

# Run the app -------------------------------------------------------
shinyApp(ui = ui, server = server)
