
plotgardener.shiny.function <- function(bw.file, hic.file, bed.file, bedpe.file, chr, start, end){

     #### prepare data for plotting when needed:
  # For bigwigs that has to be compared using t he same scale we should calculate the max scale to set
  maxScore <- max(c(readBigwig(bw.file[1])$score, 
                    readBigwig(bw.file[2])$score))
  
  print(paste("Scale for bigwig files has been set to:", maxScore-300))

  # To avoid loading too heavy data just read a specific chrom region
  hicDataChromRegion <- readHic(file = hic.file,
      chrom = as.numeric(chr), assembly = "hg38",
      chromstart = start, chromend = end,
      resolution = 25000, res_scale = "BP", norm = "KR"
  ) 
  
  # generate the plot
  
  ## Set parameters regarding the region that we would like to visualize. Those can be imported from every plot that we want to add.
params <- pgParams(
    chrom = paste("chr", chr, sep=""), chromstart = start, chromend = end,
    assembly = "hg38",
    x = 0.5, just = c("left", "bottom"),
    width = 16, length = 16, default.units = "cm",
    range = c(0, maxScore-300) # this line sets the range for bigwig tracks, when we want to plot all of the in the same range, otherwise one specific can be plotted for each separately.
)



## Create a plotgardener page
pageCreate(
    width = 16, height = 16, default.units = "cm",
    showGuides = F, xgrid = 0, ygrid = 0
)


## Plot Hi-C data in region
 plotHicTriangle(
    data = hicDataChromRegion,
  params = params,
    y = 3,  height = 3,
)

## Plot signal track data bw file1
 plotSignal(
    data = bw.file[1],
    params = params,
    y = "1.5b", height = 1.5
)
## Add text labels
plotText(
    label = "Kidney cortex 12", fonsize = 10, fontcolor = "#37a7db",
    x = 0, y = "-1b", just = c("right", "bottom"),
    params = params
)
## Plot signal track data bw file2
plotSignal(
    data = bw.file[2],
    params = params,
    y = "1.5b", height = 1.5,
    linecolor = "#7ecdbb",
)

plotText(
    label = "Kidney cortex 15", fonsize = 10, fontcolor = "#7ecdbb",
     x = 0, y = "-1b", just = c("right", "bottom"),
    params = params
)

## Plot bed files
plotRanges(
  data = bed.file,
  collapse = T,
  fill = "purple",
  y = "0.5b", height = 0.5,
  params = params
)

plotText(
    label = "ATAC peak", fonsize = 10, fontcolor = "purple",
    x = 0, y = "0b", just = c("right", "bottom"),
    params = params
)


## Plot loop annotations
plotPairsArches(
    data = bedpe.file,
    y = "1b", height = 1,
    fill = "black", linecolor = "black", flip = TRUE,
    params = params
)
plotText(
    label = "HiC arches", fonsize = 10, fontcolor = "black",
    x = 0, y = "0b", just = c("right", "bottom"),
    params = params
)


## Plot gene track
plotGenes(
    y = "1.75b", height = 1.25,
    params = params
)
plotText(
    label = "Gene", fonsize = 10, fontcolor = "black",
    x = 0, y = "0b", just = c("right", "bottom"),
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
