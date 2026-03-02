
plotgardener.shiny.function <- function(bw.file, hic.file, bed.file, bedpe.file, bw.names, hic.names, bed.names, bedpe.names, gwas.file, gwas.names, cat.file, cat.names, cat.collapse, chr, start, end, bw.mode, bw.autoscale, expand.transcripts, genes.hgnc, genome, cytoband, ideogram){
  
  
  
  ################################## INIZIO PREPROCESSING OF FILES ####################
  
     #### prepare data for plotting when needed:
  
  ## Get sizes of chromosomes to scale their sizes, used for genomic annotation tracks
  # define organism
  if (genome %in% c("hg19", "hg38", "T2T")){
    org <- "Hsapiens"
  } else if (genome %in% c("mm10", "mm39")){
    org <- "Mmusculus"
  }
  # define TxDb
  tx_db <- get(paste("TxDb.", org, ".UCSC.", genome, ".knownGene", sep=""))
  chromSizes <- GenomeInfoDb::seqlengths(tx_db)
  maxChromSize <- max(chromSizes)
  
  # define assembly for non-default genomes
  if (genome == "mm39"){
    genome <- assembly(Genome = "mm39",
                     TxDb = "TxDb.Mmusculus.UCSC.mm39.knownGene",
                     OrgDb = "org.Mm.eg.db",
                     BSgenome = "BSgenome.Mmusculus.UCSC.mm39")

  } else if (genome == "T2T") {
    genome <- assembly(Genome = "T2T",
                    OrgDb = "org.Hs.eg.db",
                    TxDb = "TxDb.Hsapiens.UCSC.T2T.knownGene",
                    BSgenome = "BSgenome.Hsapiens.NCBI.T2T.CHM13v2.0",
                    gene.id.column = "SYMBOL")
  } 
  
  # Calculate the max y-axis scale value for bigwig depending on the user selected option. A value will be assigned to each bw.
  # Default option will be to use a unique scale for each file
  
  maxScore <- 10
  if(length(bw.file) > 0){
    maxScore <- list()
    nameScore <- c()
    # set max y when autoscale is not selected (autoscale all samples together)
    if(is.null(bw.autoscale)){
      for (i in 1:length(bw.file)){
        maxScore[[i]] <- round(max(readBigwig(bw.file[i], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)$score), 1)
      }
      if (!max(unlist(maxScore)) == 0){
        maxScore <- rep(list(c(0, round(max(unlist(maxScore)), 1))), length(bw.file)) } else {
          maxScore <- rep(list(c(0, 10)), length(bw.file))
        }
      # Individual autoscale checked
    } else if (length(bw.autoscale) == length(bw.file)) {
      maxScore <- rep(list(NULL), length(bw.file))
      # Grouped autoscale selected
    } else { #maxScore <- list()
      for (l in 1:length(bw.autoscale)){
        maxGroup <- sapply(bw.autoscale[[l]], function(x) max(readBigwig(bw.file[which(bw.names == x)], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)$score))
        maxScore <- c(maxScore, rep(list(c(0, round(max(maxGroup), 1))), length(bw.autoscale[[l]])))
        nameScore <- c(nameScore, bw.names[which(bw.names %in% bw.autoscale[[l]])])
      }
      maxScore <- c(maxScore, rep(list(NULL), length(bw.file) - length(maxScore)))
      nameScore <- c(nameScore, setdiff(bw.names, nameScore))
      names(maxScore) <- as.factor(nameScore)
      # Sort scores according to samples names in bw.names as defined in config so you loop on them correctly in the plot section
      maxScore <- maxScore[order(match(names(maxScore), bw.names))]
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
     
         # Ensure resolution availability
         if (resolution %in% strawr::readHicBpResolutions(hic.file[i])){
           hic.res <- resolution
         } else {  
           available.res <- strawr::readHicBpResolutions(hic.file[i])
           hic.res <- available.res[which.min(abs(available.res - resolution))] 
         }
         
         # Ensure chromosome naming compatibility
         if (length(grep("chr", strawr::readHicChroms(hic.file[i])$name)) > 0){
           hic.chrom <- paste0("chr", chr)
         } else { hic.chrom <- as.character(chr) 
         }
         # Ensure normalization method availability
         if ("KR" %in% strawr::readHicNormTypes(hic.file[i])){
           hic.norm <- "KR"
         } else { hic.norm <- strawr::readHicNormTypes(hic.file[i])[1] 
         }
         
         hicDataChromRegion[[i]] <- readHic(file = hic.file[i],
                                            chrom = hic.chrom, assembly = genome,
                                            chromstart = start, chromend = end,
                                            resolution = hic.res, res_scale = "BP", norm = hic.norm
         ) 
        } 
      }
    }
    
    
    ################################## END PREPROCESSING OF FILES ####################
  
  #--------------------------------------------------------- generate the plot
  #####------------------------------------------------ PAGE

  ## Set parameters regarding the region that we would like to visualize. Those can be imported from every plot that we want to add.
params <- pgParams(
    chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end,
    assembly = genome,
    x = 0, just = c("left", "bottom"),
    width = 16, length = 16, default.units = "cm",
    #range = c(0, maxScore) # this line sets the range for bigwig tracks, when we want to plot all of the in the same range, otherwise one specific can be plotted for each separately.
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
          hicPlot <- plotHicTriangle(
            data = hicDataChromRegion[[i]],
            zrange = c(0, 100),
            params = params,
            y = 3.2*conv,  height = 3*conv)
          
          ## Add text labels
          plotText(
            label = hic.names[i], fontsize = 10*(conv+0.2)*conv, fontcolor = "black",
            x = -0.5, y = paste(-1*conv,"b", sep=""), just = c("right", "bottom"),
            params = params)
          
          ## Add heatmap legend
          annoHeatmapLegend(
            plot = hicPlot, x = 6.5, y = paste(-1.8*conv,"b", sep=""),
            width = 0.10, height = 0.7, fontsize = 10*(conv+0.2),
            just = c("right", "top"), fontcolor = "black"
          )
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
       scale = T,
       fontsize = 8*(conv+0.2),
       col = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
       linecolor = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
       fill = rep(paletteer_d("ggthemes::Hue_Circle"), 2)[i],
       range = maxScore[[i]],
       params = params,
       y = paste(1.5*conv, "b", sep=""), 
       height = 1.4*conv)
   
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
      # plot as ranges or as density based on the width of the genomic region
       for (i in 1:length(bed.file)){
         if(end - start <= 10e+6){
          # bed signal
          plotRanges(
          data = bed.file[i],
          collapse = endsWith(bed.file[i], ".bed"),
          fill = as.character(rep(paletteer_d("ggthemes::excel_Ion_Boardroom"), 5)[i]),
          y = paste(0.75*conv, "b", sep=""), height = 0.75*conv,
          params = params)
         } else {
           bed.den <- read.csv.sql(bed.file[i], paste("select V1, V2 from file where V1 = '", paste("chr", chr, sep=""), "'", sep =""), sep="\t", header = F, eol = "\n")
           bed.density.plot <- ggplot(bed.den, aes(x = V2)) +
             geom_density(fill = as.character(rep(paletteer_d("ggthemes::excel_Ion_Boardroom"), 5)[i]), alpha = 0.7, bw = 50000, color = as.character(rep(paletteer_d("ggthemes::excel_Ion_Boardroom"), 5)[i])) +
             xlim(start, end) +
             theme_void() +
             theme(plot.margin = grid::unit(c(0,0,0,0), "mm"),
                   # panel.border = element_rect(color = "black", 
                   #                            fill = NA, 
                   #                            size = 2)
             
             )
           bed.den <- NULL
           plotGG(bed.density.plot,
                  x = -0.7, paste(0.75*conv, "b", sep=""), height = 0.75*conv, width = 17.4,
                  params = params
           )
         }
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
      ## Assign x axis position
      x.pos  <-  16.45
     for (i in 1:length(cat.file)){
        # bed positions
        plotRanges(
         data = cat.file[i],
         collapse = cat.collapse[i],
          fill = colorby("category", palette =  colorRampPalette(c(paletteer_d("ggthemr::flat"), paletteer_d("ggthemes::Nuriel_Stone"))[1:length(unique(read_delim(cat.file[i], "\t", col_names = T, show_col_types = F)$category))])),
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
        cat.h <- (0.35*length(c(unique(read_delim(cat.file[i], "\t", col_names = T, show_col_types = F)$category)))*(conv+0.2))
        legend <-  c(sort(unique(read_delim(cat.file[i], "\t", col_names = T, show_col_types = F)$category)))
      if(i > 1 && all(legend == sort(unique(read_delim(cat.file[i-1], "\t", col_names = T, show_col_types = F)$category)))){
        next
      } else {
     plotLegend(
       legend = legend,
       fill = as.character(c(paletteer_d("ggthemr::flat"), paletteer_d("ggthemes::Nuriel_Stone"))[1:length(unique(read_delim(cat.file[i], "\t", col_names = T, show_col_types = F)$category))]),
        border = FALSE,
       x = x.pos, y = paste(-cat.h, "b", sep = ""), width = 1.5, height = cat.h,
       just = c("left", "top"),
        default.units = "cm",
       fontsize = 10*(conv+0.2)
      ) 
      }
      ## Increment x axis position
      x.pos <- x.pos+0.8
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
    label = bedpe.names[i], fontsize = 10*(conv+0.2), fontcolor = "black",
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
                  lty = 2, range = c(0, 10),
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
   # annoHeatmapLegend(
    #  plot = man.plot, fontcolor = "black",
    #  x = 6.5, y = "-0.9b", just = c("left", "top"),
    #  width = 0.10, height = 0.5, fontsize = 10*(conv+0.2), digits = 1, scientific = T
    #)
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
           params = params, labels = "both"
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

  if(ideogram == TRUE){
    
    ## Plot and place ideogram
    if (genome[1] %in% c("hg19", "hg38", "mm10")){
      
      ideogramPlot <- plotIdeogram(
        chrom = paste("chr", chr, sep=""), assembly = genome,
        x = 0.75, y = "1.75b", width = (15 * chromSizes[[paste("chr", chr, sep="")]]) / maxChromSize, height = 0.5,
        just = c("left", "bottom"),
        default.units = "cm")
      
      ## Increment y coord
      y.coord <- y.coord+0.5
      
      ## Add highlight region
      region <- pgParams(chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)
      annoHighlight(
        plot = ideogramPlot, params = region,
        fill = "darkred",
        y = "-0.6b", height = 0.7, just = c("left", "top"), default.units = "cm"
      )
      
    } else {
      ## Define region and cytoband data
      region <- pgParams(chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)
      cytoband_data <- dplyr::filter(cytoband, seqnames == paste("chr", chr, sep=""))
      ## Plot cytoband as ggplot object and add zoom highlight
      ideo <- ggplot(cytoband_data, aes(x = seqnames, ymin = start, ymax = end, fill = gieStain)) +
        geom_rect(aes(xmin = 0, xmax = 2)) +
        ggchicklet:::geom_rrect(aes(xmin=0, xmax =2, ymin=0, ymax=max(end)), fill="transparent", color="slategray") +
        coord_flip() + # Optional: Flip coordinates for a vertical ideogram
        theme_void() +# Optional: Remove default ggplot theme elements
        theme(legend.position = "none") +
        scale_fill_manual(values = c(paletteer_d("RColorBrewer::Greys")[1:length(grep("gneg*|gpos*", unique(cytoband_data$gieStain)))], rev(paletteer_dynamic("cartography::pastel.pal",5 ) [1:(length( unique(cytoband_data$gieStain))-length(grep("gneg*|gpos*", unique(cytoband_data$gieStain))))]))) +
        annotate(geom = "rect", xmin = 0, xmax = 2, ymin = region$chromstart, ymax = region$chromend, color = "darkred", fill = "darkred", alpha = 0.5)
      
      ideogramPlot <- plotGG(ideo,
                             x = 0.75 , y = "1.25b", width = (15 * chromSizes[[paste("chr", chr, sep="")]]) / maxChromSize, height = 0.5, params = region,
                             just = c("left", "bottom"),
                             default.units = "cm")
      
      ideogramPlot$chrom <- paste("chr", chr, sep="")
      ## Increment y coord
      y.coord <- y.coord+0.5
      
    }
    y.coord = y.coord -0.85
    print(y.coord)
    ## Add zoom-in lines
    annoZoomLines(params = region, 
                  plot = ideogramPlot, 
                  y0 = y.coord+0.4, x1 = c(0, 16), y1 = y.coord, default.units = "cm", just = c("left", "bottom")
    )
    
    
    ## Plot chromosome name
    #plotText(
    #  label = paste("Chromosome", chr, sep=""), fontcolor = "dark grey",
    #  x = 4.5, y = "0.5b", just = "right")
    #y.coord <- y.coord+0.5
    # COmmented because redundant with GenomeLabel
    
    
  }

}


#plotgardener.shiny.function(bw.file = bw.file, 
  #                          hic.file = hic.file, 
   #                         bed.file = bed.file, 
    #                        bedpe.file = bedpe.file,
     #                       bw.names = config$bw.names,
      #                      hic.names = config$hic.names,
       #                     bed.names = config$bed.names,
        #                    bedpe.names = config$bedpe.names,
         #                   gwas.file = gwas.file,
          #                  gwas.names = config$gwas.names,
           #                 cat.file = cat.file,
            #                cat.names = config$cat.names,
                   #         cat.collapse = T,
             #               chr = chr,
              #              start = chrstart, 
               #             end = chrend,
                #            bw.mode = "Profile",
                 #           expand.transcripts = F,
                  #          genes.hgnc = genes.hgnc)

#chr <- "4"
#chrstart <- 1
#chrend <- 190214555
