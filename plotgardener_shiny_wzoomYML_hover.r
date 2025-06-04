
plotgardener.shiny.function <- function(bw.file, hic.file, bed.file, bedpe.file, bw.names, hic.names, bed.names, bedpe.names, gwas.file, gwas.names, cat.file, cat.names, cat.collapse, chr, start, end, bw.mode, expand.transcripts, genes.hgnc){
  
  
  
  ################################## INIZIO PREPROCESSING OF FILES ####################
  
     #### prepare data for plotting when needed:
  # For bigwigs that has to be compared using the same scale we should calculate the max scale to set
  
  # read bw file to use later
  maxScore <- 10
  if(length(bw.file) > 0){
    maxScore <- c()
  for (i in 1:length(bw.file)){
    maxScore <- c(maxScore, max(readBigwig(bw.file[i], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)$score))
  }
  if (!max(maxScore) == 0){
    maxScore <- max(maxScore) } else {
      maxScore <- 10
    }

    print(paste("Scale for bigwig files has been set to:", maxScore))
    
  # Add colors based on bigwig score to be used in the Heatmap version of bigwig tracks
    ## Conditional binsize
    if ((end - start) < 10e+05){
      binsize = NA
    } else if ((end - start) >= 10e+05 & (end - start) < 5e+06){
      binsize = 5000
    } else if ((end - start) >= 5e+06 & (end - start) < 50e+06){
      binsize = 50000
    } else if ((end - start) >= 50e+06 & (end - start) < 200e+06){
      binsize = 500000
    } else {
      binsize = 1000000
    }
    print(paste0("Bigwigs binsize = ", binsize))
    
    ## Define binning of the selected region
    if (bw.mode == "Heatmap" | bw.mode == "Profile and Heatmap"){
      if(!is.na(binsize)){
       bin <- seq(from = start, to = end, by = binsize)
       print(paste("Generating ", length(bin), " bins of lenght: ", binsize))
    ## Subset the bw file based on the new binning and assign score for colouring
       score.new <- c()
        start.new <- c()
        end.new <- c()
        bw.list <- list()
       hm.colors <- list()
        for (i in 1:length(bw.file)){
          bw <- readBigwig(bw.file[i], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)
          for (b in 1:length(bin)){
             score.new <- c(score.new, mean(bw$score[which(bw$start >= bin[b] & bw$end <= (bin[b]+binsize))])) 
             start.new <- c(start.new, bin[b])
            end.new <- c(end.new, bin[b]+binsize)
           }
    
        bw.new <- data.frame(chr=paste("chr",chr, sep=""),
                         start=start.new,
                         end=end.new,
                         score=score.new)
         bw.list[[i]] <- bw.new
         print("Assigning colors to bins")
          hm.colors[[i]] <- mapColors(vector = score.new, palette = colorRampPalette(c("#2D3164", "#E4DA64", "#E6d25c", "#EAB720","#EAA928", "#E89E16", "#F1731D", "#F5191C")), range = c(0, 50)) #c("white","#4Cb9cc", "#005691","#00366C")
        }
       } else {
         hm.colors <- list()
           for (i in 1:length(bw.file)){
             bwScore <- c(readBigwig(bw.file[i], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)$score)
              hm.colors[[i]] <- mapColors(vector = bwScore, palette = colorRampPalette(c("#2D3164", "#E4DA64", "#E6d25c", "#EAB720","#EAA928", "#E89E16", "#F1731D", "#F5191C")), range = c(0, 50)) #c("white","#4Cb9cc", "#005691","#00366C")
         }
       }
      print("Binning colour assigned")
    }
  }
    
  # To avoid loading too heavy data just read a specific chrom region
    # Do this only if the region to be plotted is larger than the hiC map resolution
    hicDataChromRegion <- list()
    if(length(hic.file) > 0){
      if((end - start >= 15000)){
       for (i in 1:length(hic.file)){
       # Conditional resolution based on plotting region size
         if ((end - start) <= 25000){
         resolution = 15000
         } else if ((end - start) > 25000 & (end - start) <= 10e+05){
            resolution = 25000 } else if ((end - start) > 10e+05 & (end - start) <= 5e+06){
            resolution = 100000
         } else {
            resolution = 500000
          }
     
      hicDataChromRegion[[i]] <- readHic(file = hic.file[i],
         chrom = as.numeric(chr), assembly = "hg38",
         chromstart = start, chromend = end,
        resolution = resolution, res_scale = "BP", norm = "KR"
          ) 
        } 
      }
    }
    
    ## Get sizes of chromosomes to scale their sizes, used for genomic annotation tracks
    tx_db <- TxDb.Hsapiens.UCSC.hg38.knownGene
    chromSizes <- GenomeInfoDb::seqlengths(tx_db)
    maxChromSize <- max(chromSizes)
    
    ################################## END PREPROCESSING OF FILES ####################
  
  #--------------------------------------------------------- generate the plot
  #####------------------------------------------------ PAGE

  ## Set parameters regarding the region that we would like to visualize. Those can be imported from every plot that we want to add.
params <- pgParams(
    chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end,
    assembly = "hg38",
    x = 0, just = c("left", "bottom"),
    width = 16, length = 16, default.units = "cm",
    range = c(0, maxScore) # this line sets the range for bigwig tracks, when we want to plot all of the in the same range, otherwise one specific can be plotted for each separately.
)

# Define counter for y coordinate:
  y.coord <- 0


## Create a plotgardener page
  page.height <- 20.1 
  conv <- (page.height-6)/((2*length(bw.file))+(0.75*length(bed.file))+(0.75*length(bedpe.file))+(length(hic.file)*3)+(0.75*length(cat.file))+(length(gwas.file)*2))
  if ( conv > 1){conv <-  1 } # to avoid plotting data too big
   
  pageCreate(
    width = 16, height = page.height, default.units = "cm",
    showGuides = F, xgrid = 0, ygrid = 0
)

#####------------------------------------------------ Plot a segment to have the starting point for whatever other graph
    ## Plot fictitious range
    plotRanges(data = data.frame(chr = paste("chr", chr, sep=""), start = start, end = end),
               params = params,
               fill = "#7ecdbb",
               linecolor = NA,
               y = y.coord, height = 0.1)
    y.coord <- y.coord + 0.1
    print(y.coord)
    
#####------------------------------------------------ HiC Matrix
    ## Plot Hi-C data in region
    if(isEmpty(hicDataChromRegion)){} else {
      for (i in 1:length(hicDataChromRegion)){
        if(nrow(hicDataChromRegion[[i]][1]) <= 1){} else {
          plotHicTriangle(
            data = hicDataChromRegion[[i]],
            params = params,
            y = 3.2*conv,  height = 3*conv)
          
          ## Add text labels
          plotText(
            label = hic.names[i], fontsize = 10*(conv+0.2)*conv, fontcolor = "black",
            x = -0.5, y = paste(-1*conv,"b", sep=""), just = c("right", "bottom"),
            params = params)
          
          ## Increment y coord
          y.coord <- y.coord+(3.2*conv)
        }
      }
    }
    print(y.coord)

#####------------------------------------------------ BIGWIGS

  ## Conditional binsize applied as defined in rows 15 to 24 (Conditional binsize)
  
  
  
## Plot signal and text track data bw files
if(length(bw.file) > 0){
if (bw.mode == "Profile" | bw.mode == "Profile and Heatmap"){
  for (i in 1:length(bw.file)){
    # Bw signal
     plotSignal(
       data = bw.file[i],
       binSize = binsize,
       binCap = F,
      linecolor = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
      fill = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
       params = params,
       y = paste(1.5*conv, "b", sep=""), 
       height = 1.5*conv)
   
     ## Add text labels
     plotText(
      label = bw.names[i], fontsize = 10*(conv+0.2), fontcolor = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
      x = -0.5, y = paste(-0.5*conv, "b", sep=""), just = c("right", "bottom"),
       params = params)
     
     ## Increment y coord
     y.coord <- y.coord+(1.5*conv)
  }
 }

## Plot bigwig as heatmap
  if (bw.mode == "Heatmap" | bw.mode == "Profile and Heatmap"){
   for (i in 1:length(bw.file)){
     # bed signal
     if(!is.na(binsize)){
       hm.plot <- plotRanges(
         data = bw.list[[i]],
         collapse = T,
         fill = hm.colors[[i]],
         y = paste(0.75*conv, "b", sep=""), height = conv*0.75,
         params = params)} else {
           hm.plot <- plotRanges(
             data = bw.file[i],
             collapse = T,
             fill = hm.colors[[i]],
             y = paste(0.75*conv, "b", sep=""), height = conv*0.75,
             params = params)}
    
    ## Add text labels
      plotText(
       label = bw.names[i], fontsize = 10*(conv+0.2), fontcolor = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
        x = -0.5, y = "0b", just = c("right", "bottom"),
        params = params)
      
      ## Increment y coord
      y.coord <- y.coord+(0.75*conv)
   }
    ## Add heatmap legend just once
    annoHeatmapLegend(
      plot = hm.plot, fontcolor = "black",
      x = 6.5, y = "-0.5b", just = c("left", "top"),
      width = 0.10, height = 0.5, fontsize = 10*(conv+0.2)
    )
  }
}
    print(y.coord)

#####------------------------------------------------ BED
## Plot bed files
    if(length(bed.file) > 0){
  for (i in 1:length(bed.file)){
   # bed signal
  plotRanges(
    data = bed.file[i],
   collapse = T,
   fill = as.character(rep(paletteer_d("ggthemes::excel_Ion_Boardroom"), 5)[i]),
   y = paste(0.75*conv, "b", sep=""), height = 0.75*conv,
   params = params)
   
   ## Add text labels
  plotText(
    label = bed.names[i], fontsize = 10*(conv+0.2), fontcolor = rep(paletteer_d("ggthemes::excel_Ion_Boardroom"), 5)[i],
    x = -0.5, y = "0b", just = c("right", "bottom"),
    params = params)

  ## Increment y coord
  y.coord <- y.coord+(0.75*conv)
      }
    }
    print(y.coord)
    
#####------------------------------------------------ CATEGORICAL BED  
  ## Plot categorical bed files
    if(length(cat.file) > 0){
     for (i in 1:length(cat.file)){
        # bed positions
        plotRanges(
         data = cat.file[i],
         collapse = cat.collapse[i],
          fill = colorby("category", palette =  colorRampPalette(c(paletteer_d("ggthemr::flat"), paletteer_d("ggthemes::Nuriel_Stone"))[1:length(unique(read.table(cat.file[i], sep = "\t", header = T)$category))])),
          y = paste(0.75*conv, "b", sep=""), height = 0.75*conv,
          params = params)
      
        ## Add text labels
        plotText(
         label = cat.names[i], fontsize = 10*(conv+0.2), fontcolor = "black",
         x = -0.5, y = "0b", just = c("right", "bottom"),
         params = params)
      
        ## Increment y coord
        y.coord <- y.coord+(0.75*conv)
        
        ## Calculate legend height
        cat.h <- (0.3*length(c(unique(read.table(cat.file[i], sep = "\t", header = T)$category)))*(conv+0.2))
  
    
     plotLegend(
       legend = c(unique(read.table(cat.file[i], sep = "\t", header = T)$category)),
       fill = as.character(c(paletteer_d("ggthemr::flat"), paletteer_d("ggthemes::Nuriel_Stone"))[1:length(unique(read.table(cat.file[i], sep = "\t", header = T)$category))]),
        border = FALSE,
       x = 16.45, y = paste(-cat.h, "b", sep = ""), width = 1.5, height = cat.h,
       just = c("left", "top"),
        default.units = "cm",
       fontsize = 10*(conv+0.2)
      )
       }
    }
    print(y.coord)

#####------------------------------------------------ HiC LOOPS
## Plot loop annotations
  if(length(bedpe.file) > 0){
    bedpe.h <- 2*conv
 for (i in 1:length(bedpe.file)){
  plotPairsArches(
    data = bedpe.file[i],
    y = paste(bedpe.h, "b", sep=""), height = 2*conv,
    fill = "black", linecolor = "black", flip = TRUE,
    params = params
  )
  plotText(
    label = bedpe.names, fontsize = 10*(conv+0.2), fontcolor = "black",
    x = -0.5, y = paste(-0.5*conv, "b", sep=""), just = c("right", "top"),
    params = params
  )
  
  ## Increment y coord
  y.coord <- y.coord+(2*conv)
     }
  }
    print(y.coord)
    
#####------------------------------------------------ GWAS Manhattan
## Plot Manhattan for GWAS
    if(length(gwas.file) > 0){
    for (i in 1:length(gwas.file)){
     man.plot <-  plotManhattan(
                  data = gwas.file[i], 
                  params = params,
                  fill = colorby("p", palette = colorRampPalette(paletteer_c("grDevices::Plasma", 30))),
                  trans = "-log10",
                  sigLine = TRUE, col = "grey",
                  lty = 2, range = c(0, 40),
                  y = "0b",
                  height = 2*conv,
                  just = c("left", "top")
                  )
      ## Annotate y-axis
      annoYaxis(
        plot = man.plot,
        axisLine = F, fontsize = 8*(conv+0.2)
      )
      ## Plot y-axis label
      plotText(
        label = "-log10(p)", x = -1, y = "0b", rot = 90,
        fontsize = 9*(conv+0.2), fontface = "bold", just = c("left, bottom"),
        params = params
      )
      ## Add text labels
      plotText(
        label = gwas.names[i], fontsize = 8*(conv+0.2), fontface = "bold", fontcolor = "black",
        x = -1.25, y = "0b", just = c("right", "center"),
        params = params
        )
      ## Increment y coord
      y.coord <- y.coord+(2*conv)
      
    }
    
    ## Add heatmap legend just once
    annoHeatmapLegend(
      plot = man.plot, fontcolor = "black",
      x = 6.5, y = "-0.9b", just = c("left", "top"),
      width = 0.10, height = 0.5, fontsize = 10*(conv+0.2), digits = 1, scientific = T
    )
    }
    print(y.coord)

#####------------------------------------------------ GENE and GENOME TRACKS

    # If the genomic region to be plotted is shorted than 10 Mb plot genes or transcript tracks, otherwise plot just genes density
    if(end - start <= 10e+6){
    ## Plot gene track
     if(!expand.transcripts == TRUE){
        plotGenes(
          y = "1.5b", height = 1.5,
          params = params
        )
       plotText(
          label = "Gene", fontsize = 10*(conv+0.2), fontcolor = "black",
          x = -0.5, y = "0b", just = c("right", "bottom"),
          params = params
        )
        y.coord = y.coord + 1.5} else { 
         plotTranscripts(
            y = "3b", height = 3,
           params = params, labels = "gene"
         )
          plotText(
           label = "Transcripts", fontsize = 10*(conv+0.2), fontcolor = "black",
           x = -0.5, y = "0b", just = c("right", "bottom"),
            params = params
          )
          y.coord = y.coord + 3
        }
      } else {
        gene.density.plot <- ggplot(filter(genes.hgnc, chromosome_name == chr), aes(x = start_position)) +
          geom_density(fill = "skyblue", alpha = 0.7, bw = 100000, color = "skyblue") +
          xlim(start, end) +
          theme_void() +
          theme(plot.margin = grid::unit(c(0,0,0,0), "mm"),
               # panel.border = element_rect(color = "black", 
                #                            fill = NA, 
                #                            size = 2)
               )
        
        plotGG(gene.density.plot,
               x = -0.7, y = "1.5b", height = 1.5, width = 17.4,
               params = params
               )
        plotText(
          label = "Gene density", fontsize = 10*(conv+0.2), fontcolor = "black",
          x = -0.5, y = "0b", just = c("right", "bottom"),
          params = params
        )
        y.coord = y.coord + 1.5
      }



## Plot genome label
  plotGenomeLabel(
     params = params,
       y = "0.5b", scale = "Mb",
     fontsize = 11*(conv+0.2)
  )
  y.coord = y.coord + 1

  print(y.coord)

#####------------------------------------------------ CHROMOSOME IDEOGRAM
# Plot chromosome ideogram:

## Plot and place ideogram
ideogramPlot <- plotIdeogram(
  chrom = paste("chr", chr, sep=""), assembly = "hg38",
  x = 0.75, y = "1.25b", width = (15 * chromSizes[[paste("chr", chr, sep="")]]) / maxChromSize, height = 0.5,
  just = c("left", "bottom"),
  default.units = "cm"
)
## Increment y coord
y.coord <- y.coord+0.5

## Plot chromosome name
#plotText(
#  label = paste("Chromosome", chr, sep=""), fontcolor = "dark grey",
#  x = 4.5, y = "0.5b", just = "right")
#y.coord <- y.coord+0.5
# COmmented because redundant with GenomeLabel

## Add highlight region
region <- pgParams(chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)
annoHighlight(
  plot = ideogramPlot, params = region,
  fill = "darkred",
  y = "-0.6b", height = 0.7, just = c("left", "top"), default.units = "cm"
)

print(y.coord)

## Add zoom-in lines
annoZoomLines(
  plot = ideogramPlot, params = region,
  y0 = y.coord, x1 = c(0, 16), y1 = y.coord+0.75, default.units = "cm"
)

}


#plotgardener.shiny.function(bw.file = bw.file, 
#                            hic.file = hic.file, 
#                            bed.file = bed.file, 
#                            bedpe.file = bedpe.file,
#                            bw.names = config$bw.names,
#                            hic.names = config$hic.names,
#                            bed.names = config$bed.names,
#                            bedpe.names = config$bedpe.names,
#                            gwas.file = gwas.file,
#                            gwas.names = config$gwas.names,
#                            cat.file = cat.file,
#                            cat.names = config$cat.names,
#                            cat.collapse = T,
#                            chr = chr,
#                            start = start, 
#                            end = end,
#                            bw.mode = "Profile",
#                            expand.transcripts = F,
 #                           genes.hgnc = genes.hgnc)

#chr <- "1"
#chrstart <- 28000000
#chrend <- 30300000
