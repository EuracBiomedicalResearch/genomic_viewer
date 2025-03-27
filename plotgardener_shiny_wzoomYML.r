
plotgardener.shiny.function <- function(bw.file, hic.file, bed.file, bedpe.file, bw.names, hic.names, bed.names, bedpe.names, chr, start, end, bw.mode){

     #### prepare data for plotting when needed:
  # For bigwigs that has to be compared using the same scale we should calculate the max scale to set
  maxScore <- c()
  for (i in 1:length(bw.file)){
    maxScore <- c(maxScore, max(readBigwig(bw.file[i], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)$score))
  }
  maxScore <- max(maxScore)

    print(paste("Scale for bigwig files has been set to:", maxScore))
    
  # Add colors based on bigwig score to be used in the Heatmap version of bigwig tracks
    ## Map score column to a vector of colors
    hm.colors <- list()
    for (i in 1:length(bw.file)){
      bwScore <- c(readBigwig(bw.file[i], chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end)$score)
      hm.colors[[i]] <- mapColors(vector = bwScore, palette = colorRampPalette(c("#2D3184", "#E4DA64", "#E6d25c", "#EAB720","#EAA928", "#E89E16", "#F1731D", "#F5191C")), range = c(0, 50)) #c("white","#4Cb9cc", "#005691","#00366C")
    }
      
   

  # To avoid loading too heavy data just read a specific chrom region
    hicDataChromRegion <- list()
   for (i in 1:length(hic.file)){
     hicDataChromRegion[[i]] <- readHic(file = hic.file[i],
       chrom = as.numeric(chr), assembly = "hg38",
       chromstart = start, chromend = end,
       resolution = 25000, res_scale = "BP", norm = "KR"
        ) 
    }
  
  # generate the plot
  
  ## Set parameters regarding the region that we would like to visualize. Those can be imported from every plot that we want to add.
params <- pgParams(
    chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end,
    assembly = "hg38",
    x = 3, just = c("left", "bottom"),
    width = 16, length = 16, default.units = "cm",
    range = c(0, maxScore) # this line sets the range for bigwig tracks, when we want to plot all of the in the same range, otherwise one specific can be plotted for each separately.
)



## Create a plotgardener page
pageCreate(
    width = 16, height = 16, default.units = "cm",
    showGuides = F, xgrid = 0, ygrid = 0
)


## Plot Hi-C data in region
for (i in 1:length(hicDataChromRegion)){
 plotHicTriangle(
    data = hicDataChromRegion[[i]],
  params = params,
    y = 3,  height = 3)
  
  ## Add text labels
  plotText(
    label = hic.names[i], fonsize = 10, fontcolor = "black",
    x = 2.5, y = "-1b", just = c("right", "bottom"),
    params = params)
  }

## Plot signal and text track data bw files
if (bw.mode == "Profile" | bw.mode == "Profile and Heatmap"){
  for (i in 1:length(bw.file)){
    # Bw signal
     plotSignal(
       data = bw.file[i],
      linecolor = paletteer_d("colorBlindness::Blue2DarkOrange12Steps")[i],
      fill = paletteer_d("colorBlindness::Blue2DarkOrange12Steps")[i],
       params = params,
       y = "1.5b", 
       height = 1.5)
   
     ## Add text labels
     plotText(
      label = bw.names[i], fonsize = 10, fontcolor = paletteer_d("colorBlindness::Blue2DarkOrange12Steps")[i],
      x = 2.5, y = "-1b", just = c("right", "bottom"),
       params = params)
  }
 }

## Plot bigwig as heatmap
  if (bw.mode == "Heatmap" | bw.mode == "Profile and Heatmap"){
   for (i in 1:length(bw.file)){
    # bed signal
    hm.plot <- plotRanges(
      data = bw.file[i],
      collapse = T,
      fill = hm.colors[[i]],
      y = "0.5b", height = 0.5,
      params = params)
    
    ## Add text labels
      plotText(
       label = bw.names[i], fonsize = 10, fontcolor = paletteer_d("colorBlindness::Blue2DarkOrange12Steps")[i],
        x = 2.5, y = "0b", just = c("right", "bottom"),
        params = params)
   }
    ## Add heatmap legend just once
    annoHeatmapLegend(
      plot = hm.plot, fontcolor = "black",
      x = 7.75, y = "-0.9b", just = c("right", "top"),
      width = 0.10, height = 0.5, fontsize = 10
    )
  }


## Plot bed files
 for (i in 1:length(bed.file)){
   # bed signal
plotRanges(
  data = bed.file[i],
  collapse = T,
  fill = as.character(paletteer_d("ggthemes::excel_Ion_Boardroom")[i]),
  y = "0.5b", height = 0.5,
  params = params)
   
   ## Add text labels
plotText(
    label = bed.names, fonsize = 10, fontcolor = paletteer_d("ggthemes::excel_Ion_Boardroom")[i],
    x = 2.5, y = "0b", just = c("right", "bottom"),
    params = params)
 }

## Plot loop annotations
 for (i in 1:length(bedpe.file)){
  plotPairsArches(
    data = bedpe.file[i],
    y = "1b", height = 1,
    fill = "black", linecolor = "black", flip = TRUE,
    params = params
  )
  plotText(
    label = bedpe.names, fonsize = 10, fontcolor = "black",
    x = 2.5, y = "0b", just = c("right", "bottom"),
    params = params
  )
  }

## Plot gene track
plotGenes(
    y = "1.75b", height = 1.25,
    params = params
)
plotText(
    label = "Gene", fonsize = 10, fontcolor = "black",
    x = 2.5, y = "0b", just = c("right", "bottom"),
    params = params
)

## Plot genome label
plotGenomeLabel(
     params = params,
       y = "1b", scale = "Mb"
)


# Save the plot
#res = recordPlot()
# Clear the Plot Window
#plot.new()
 
# Display the saved plot
#replayPlot(res)
 
}


#plotgardener.shiny.function(bw.file = bw.file, hic.file = hic.file, bedpe.file = bedpe.file, chr = chr, start = chrstart, end = chrend)

#chr <- "1"
#start <- 28000000
#end <- 30300000
