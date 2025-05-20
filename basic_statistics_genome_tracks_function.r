
## The following script will be used to generate plots for the statistical analysis of peaks and archs graphs

########################################## Barplot of total and selected region peaks number (bed)

basic_statistics_genome_tracks <- function(bed.file, bed.names, chr, Start, End, filetype){
  chrom <- paste0("chr", chr)

  # Read bed files and peaks nr
  bed.tab.list <- list() ## Capire se serve davvero storare questa info o se posso evitare
  peaks.nr <- c() # For total nr of peaks
  peaks.nr.sel <- c() # For peaks nr in the selected region
  for (i in 1:length(bed.file)){
    bed.tab <- read.table(bed.file[i], header = F, sep= "\t")
    peaks.nr <- c(peaks.nr, nrow(bed.tab))
    # For bed files or bedpe files
    if(filetype == "bed"){
    colnames(bed.tab)[1:3] <- c("chr", "start", "end")
    bed.tab.s <- dplyr::filter(bed.tab, chr == chrom & start >= Start & end <= End)
    label <- "Peaks nr"
    } else if (filetype == "bedpe"){
      colnames(bed.tab)[1:6] <- c("chrA", "startA", "endA", "chrB", "startB", "endB")
      bed.tab.s <- dplyr::filter(bed.tab, chrA == chrom & startA >= Start & endA <= End | chrB == chrom & startB >= Start & endB <= End)
      label <- "Arches nr"
    }
    bed.tab.list[[i]] <- bed.tab.s
    peaks.nr.sel <- c(peaks.nr.sel, nrow(bed.tab.s))
  }
  
  # Summarize peaks numbers in a data frame
  peaks.nr.df <- data.frame(peaks.nr = c(peaks.nr, peaks.nr.sel),
                            category = c(rep("total", length(peaks.nr)), rep("selected", length(peaks.nr.sel))),
                            names = bed.names)
  # Generate plot of total peaks nr
  plot.bed.tot <- ggplot(peaks.nr.df, aes(x = names, y = peaks.nr)) +
    geom_bar(stat="identity", fill=paletteer_d("colorBlindness::Blue2DarkOrange12Steps")[1:length(bed.names)])+
    ggtitle(paste(label, " ",chrom, ":", Start, "-", End, sep="")) +
    ylab(label) +
    xlab("") +
    theme_minimal() +
    theme(text = element_text(size = 12),
          axis.text.y = element_text(size = 12),
          axis.text.x = element_text(size = 12),
          strip.text.x = element_text(size = 12)) +
    geom_text(aes(label=peaks.nr), vjust=1.6, color="white", size=6) +
    facet_wrap( ~ category, , scales = "free")
  
  plot.bed.tot

  # End of function
}


########################################## UPSET PLOT for peak intersection

  # Required packages: library(ChIPpeakAnno)
                     # library(rtracklayer)
                     # library(spiky)
                     # library(ggplot2)
                     # library(ComplexUpset)

      # For this type of plot we use a function that has been implemented in the EpiCompare package (https://rdrr.io/github/neurogenomics/EpiCompare/). 
      # It allows to take multiple GRanges objects (obtained from peaksets generally) and to calculate pekas overlaps and finally generate an upset plot of the intersection.
      # Generating the upset plot is important because when more than 3-5 groups of peaks are generated, the venn diagram becomes unclear and many times also impossible to represent with the most commonly used packages.
      # The functions present in the EpiCompare package are well implemented exactly for this aim, however it was not possible to make the package working (too new maybe, published  on Feb. 17, 2025). Thus the functions from the source code where copied here and reused. 

      ####### EpiCompare function copied here: BEGIN

overlap_upset_plot <- function(peaklist,
                               verbose=TRUE){
  
  value <- NULL;
  
  t1 <- Sys.time()
  
  font_size <- 1
  messager("--- Running overlap_upset_plot() ---",v=verbose)
  #### Check package is available ####
  check_dep("ComplexUpset")
  check_dep("tidyr") 
  ### Check Peaklist Names ###
  peaklist <- check_list_names(peaklist)
  ### Set Metadata Colnames ###
  # So it doesn't interfere
  for(i in seq_len(length(peaklist))){
    my_label <- make.unique(rep("name",
                                ncol(GenomicRanges::elementMetadata(peaklist[[i]])))
    )
    colnames(GenomicRanges::elementMetadata(peaklist[[i]])) <- my_label
  }
  ### Erase Names ###
  peaklist_names <- names(peaklist)
  names(peaklist) <- NULL
  ### Create Merged Dataset ###
  merged_peakfile <- do.call(c, peaklist)
  ### Calculate Overlap & Create Data Frame ###
  overlap_df <- NULL
  for(i in seq_len(length(peaklist))){
    overlap <- IRanges::findOverlaps(merged_peakfile, peaklist[[i]])
    sample_name <- rep(peaklist_names[i], length(IRanges::to(overlap)))
    df <- data.frame(peak=IRanges::from(overlap), sample=sample_name)
    unique_df <- unique(df)
    overlap_df <- rbind(overlap_df, unique_df)
  }
  ### Adjust Font Size ###  
  if(length(peaklist)>6){
    font_size <- 0.65
  }
  #### Create Upset Plot ###
  overlap_df$value <- 1
  overlap_df <- tidyr::spread(data = overlap_df, 
                              key = sample, 
                              value = value, 
                              fill=0) 
  
  base_annotations <- list(
    'Intersection size'=ComplexUpset::intersection_size(),
    'Intersection ratio'=ComplexUpset::intersection_ratio(
      text_mapping=ggplot2::aes(label=!!ComplexUpset::upset_text_percentage())
    )
  )
  plt <- ComplexUpset::upset(data = overlap_df,
                             intersect = peaklist_names,
                             base_annotations = base_annotations)
  report_time(t1 = t1,
              func="overlap_upset_plot",
              verbose = verbose)
  return(list(plot=plt,
              data=overlap_df))
}

messager <- function(..., v = TRUE, parallel = FALSE) {
  if(parallel){
    if(v) try({message_parallel(...)})
  } else {
    msg <- paste(...)
    if (v) try({message(msg)})
  }
}


check_dep <- function(dep){
  if(!requireNamespace(dep, quietly = TRUE)){
    stp <- paste("Package",shQuote(dep),
                 "must be installed to use this function.")
    stop(stp,
         call. = FALSE)
  }
}

#' Check peaklist is named
#'
#' This function checks whether the peaklist is named.
#' If not, default file names are assigned.
#'
#' @param peaklist A list of peak files as GRanges object.
#' @param default_prefix Default prefix to use when creating names
#'  for \code{peaklist}.
#' @return named peaklist
#' @keywords internal
check_list_names <- function(peaklist,
                             default_prefix="sample"){
  # check that peaklist is named
  # if not, default file names are used
  if(is.null(names(peaklist))){
    names(peaklist) <- paste0(default_prefix, seq_len(length(peaklist)))
  }
  # check for any missing names
  for(i in seq_len(length(peaklist))){
    if(is.na(names(peaklist)[i])){
      names(peaklist)[i] <- paste0(default_prefix, i)
    }
  }
  ####  Check for duplicate names ####
  dup_names <- names(peaklist)[duplicated(names(peaklist))]
  if(length(dup_names)>0){
    message(paste(length(dup_names),"duplicated peaklist names found.",
                  "Forcing unique names with make.unique()."))
    names(peaklist) <- make.unique(names(peaklist))
  }
  return(peaklist)
}

report_time <- function(t1, 
                        func=NULL,
                        verbose=TRUE){
  messager(if(!is.null(func))paste0(func,"():"),
           "Done in",
           paste0(round(difftime(Sys.time(),t1,units = "s"),1),"s."),
           v=verbose)
}

      #### USAGE
#overlap_upset_plot(peaklist = list(bed.peaks.gr, spiky::convertPairedGRtoGR(bedpe.peaks.gr)), verbose = T)
# names(peaklist) <- c("name1", "name2")



######################  HERE IS INSTEAD DEFINED MY OWN FUNCTION TO APPLY EPICOMPARE ON THE DATA LOADED IN THE APP
peaks_intersection_venn_function <- function(bed.file, bed.names, bedpe.file, bedpe.names, chr, Start, End){
  
  # Convert BED AND bedpe to GRanges:
    # BEDPE files are imported as object of class Paires, which is a double GRanges. Therefore to merge it into a single GRanges object a further step is needed with the spiky lib
 
  q=GRanges(seqnames=paste("chr", chr, sep=""),
            ranges=IRanges(start = Start, end = End))
  
  bed.peaks.list <- list()
  bed.peaks.list.s <- list()
  for (i in 1:length(bed.file)){
    bed.peaks.list[[i]] <- import(bed.file[i], format = "BED", genome = "hg38")
    bed.peaks.list.s[[i]] <- subsetByOverlaps(bed.peaks.list[[i]], q)
  }
  
  bedpe.peaks.list <- list()
  bedpe.peaks.list.s <- list()
  for (i in 1:length(bedpe.file)){
    bedpe.peaks.list[[i]] <- spiky::convertPairedGRtoGR(import(bedpe.file[i], format = "bedpe", genome = "hg38"))
    bedpe.peaks.list.s[[i]] <- subsetByOverlaps(bedpe.peaks.list[[i]], q)
  }
  
  peaklist <-  c(bed.peaks.list, bedpe.peaks.list)
  names(peaklist) <-c(bed.names, bedpe.names)
  ups <- overlap_upset_plot(peaklist = peaklist, verbose = T)


  peaklist2 <- c(bed.peaks.list.s, bedpe.peaks.list.s)
  names(peaklist2) <-c(bed.names, bedpe.names)
  peaklist2 <- Filter(function(x) length(x) > 0, peaklist2) # remove empty sublists
  if (length(peaklist2) > 1){
    ups2 <- overlap_upset_plot(peaklist = unlist(peaklist2), verbose = T)
   }
  
  if(length(peaklist) > 1 & length(peaklist2) > 1){
      ggpubr::ggarrange(ups$plot, ups2$plot, ncol = 2, nrow=1, labels = c("total", "selected"))
  } else if(length(peaklist) > 1 & length(peaklist2) <=1){
    ggpubr::ggarrange(ups$plot, ncol = 2, nrow=1, labels = c("total"))
  }
  # End of function
}

####################### FUNCTION TO PLOT THE ANNOTATION OF PEAKS COMING FROM BED FILE: ONLY FOR TOTAL PEAKS

# Plot peaks distribution over different feature levels
peaks.annotation.function <- function(bed.file, bed.names){
  ## Start of function
anno.plot.list <- list()
for (i in 1:length(bed.file)){
  anno.p <- genomicElementDistribution(import(bed.file[i], format = "BED", genome = "hg38"), 
                                       TxDb = TxDb.Hsapiens.UCSC.hg38.knownGene)
  anno.plot.list[[i]] <- anno.p$plot
}

ggpubr::ggarrange(plotlist = anno.plot.list, nrow = ceiling(length(anno.plot.list)/3), labels = bed.names)
  ## End of function
}


########################################## FUNCTION TO GENERATE A MANHATTAN PLOT ON THE SELECTED CHROMOSOME AND ZOOM-IN REGION WITH SNPs NAMES

manhattan.plot.function <- function(gwas.file, Chr, start, end, sign.p, chr.len.df, gwas.names){
  ## required libraries:
  # library(TxDb.Hsapiens.UCSC.hg38.knownGene)
  # library(plotgardener)
  # library(paletteer)
  # library(dplyr)
  
  ## Specifiy complete chromosome name
  chr = paste("chr", Chr, sep = "")
  ## Retrieve chromosome length for plotting
  chr.len <- chr.len.df$chr.len[chr.len.df$chr == chr]
  ## Define page height
  h <- 6*length(gwas.file)*2
  
  ## Define plotting parameters for whole chromosome
  params <- pgParams(
    chrom = chr, chromstart = 1, chromend = chr.len,
    assembly = "hg38",
    x = 0, just = c("left", "bottom"),
    width = 12, length = 12, height = 6, default.units = "cm"
  )
  
  ## Define plotting parameter for zoom-in region
  region <- pgParams(
    chrom = chr, chromstart = start, chromend = end,
    assembly = "hg38",
    x = 0, just = c("left", "bottom"),
    width = 12, length = 12, height = 6, default.units = "cm"
  )
  
  ################# WHOLE CHROMOSOME MANHATTAN
  ## Create page
  pageCreate(width = 12, height = h, default.units = "cm", showGuides = F) 
  
  ## Define starting y coordinate
  y.coord <- h
  
  ## Loop over every GWAS of input
  for (i in 1:length(gwas.file)){
    man.data.t <- read.table(gwas.file[i], sep = "\t", header = T)
    
    ## Define lead SNPs to be plotted wit their name specified
    leadSNP <- filter(man.data.t, chrom == chr & p < sign.p)
    
    ## Plot fictitious segment
    plotRanges(data = data.frame(chr = chr, start = 1, end = chr.len),
               params = params,
               fill = "#7ecdbb",
               linecolor = NA,
               y = y.coord, height = 0.1)
  
    ## Create Manhattan plot of the selected chromosome
    mp <- plotManhattan(
      data = man.data.t,
      fill = colorby("p", palette = colorRampPalette(paletteer_c("grDevices::Plasma", 30))),
      trans = "-log10",
      sigVal = sign.p, sigLine = TRUE, sigCol = "#7ecdbb",  col = "grey",
      lty = 2, range = c(0, 14),
      y = "0b",
      default.units = "cm",
      params = params
    )
    ## Annotate signifcant SNPs
    if(nrow(leadSNP) > 0){
    plotText(label = leadSNP$snp, 
             x = leadSNP$pos*(12/chr.len) + 0.2 , 
             y = y.coord-(-log10(leadSNP$p)*(6/14)), 
             check.overlap = T, 
             params = params,
             rot = 35)
    }
  
    ## Highlight genomic region on signal plot
    annoHighlight(
     plot = mp,
      y = "0b",
      alpha = 0.3,
     params = region
    )
    
    ## Plot graph title
    plotText(
      label = gwas.names[i],
      x = 12, y = "-6b",
      fontsize = 8, fontface = "bold", just = "right",
      params = params
    )
    
    y.coord <- y.coord + 6
  
    }
  
  ### Annotations once for every input dataset
  ## Annotate genome label
  annoGenomeLabel(
    plot = mp, 
    y = "0.5b",
    fontsize = 8, 
    scale = "Mb",
    params = params
  )
  #> genomeLabel[genomeLabel2]
  
  ## Annotate y-axis
  annoYaxis(
    plot = mp,
    at = c(0, 2, 4, 12, 8, 10, 12, 14),
    axisLine = TRUE, fontsize = 8
  )
  #> yaxis[yaxis2]
  
  ## Plot y-axis label
  plotText(
    label = "-log10(p-value)", x = -1, y = "-2.5b", rot = 90,
    fontsize = 8, fontface = "bold", just = "center",
    params = params
  )
  
  ## Color legend
  ## Add heatmap legend just once
  annoHeatmapLegend(
    plot = mp, fontcolor = "black",
    x = 12.5, y = "-2.5b",
    width = 0.3, height = 1.5, fontsize = 8, digits = 1, scientific = T,
    params = params
  )
  
  ################### ZOOM-IN MANHATTAN
  
  # Run zoom-in just if the selected region is smaller than the whole chromosome
  
  if (end < chr.len){
  ## Add zoom-in inset of the user selected region
  annoZoomLines(
    chrom = chr,
    plot = mp,
    prams = params,
    chromstart = start,
    chromend = end,
    y0 = 6, y1 = 5.5,
    x1 = c(0, 12),
    default.units = "cm"
  )
  
  ## Define starting y coord for zoom panels
  y.coord.z <- 5
  
  ## Loop over every GWAS of input
  for (i in 1:length(gwas.file)){
    man.data.t <- read.table(gwas.file[i], sep = "\t", header = T)
    
    ## Define lead SNPs to be plotted wit their name specified
    leadSNP <- filter(man.data.t, chrom == chr & p < sign.p)
    
    ## Create Manhattan plot of the selected chromosome
    mp2 <- plotManhattan(
      data = man.data.t,
      fill = colorby("p", palette = colorRampPalette(paletteer_c("grDevices::Plasma", 30))),
      trans = "-log10",
      sigVal = sign.p, sigLine = TRUE, sigCol = "#7ecdbb",  col = "grey",
      lty = 2, range = c(0, 14),
      y = y.coord.z,
      default.units = "cm",
      params = region,
      label = "zoom"
    )
    ## Annotate significant SNPs
    if(nrow(leadSNP > 0)){
    plotText(label = leadSNP$snp, 
             x = (leadSNP$pos-start)*(12/(end - (start-1))) + 0.2 , 
             y = y.coord.z-(-log10(leadSNP$p)*(6/14)), 
             check.overlap = T, 
             params = region,
             rot = 35)
    }
    
    y.coord.z <- y.coord.z - 6 
    
    ## Plot graph title
    plotText(
      label = paste("Zoom-in: ", gwas.names[i], sep=""),
      x = 6, y = "-6b",
      fontsize = 8, fontface = "bold", just = "center",
      params = region
    )
    
  }
  
  ### Annotations once for every input dataset
  ## Annotate genome label
  annoGenomeLabel(
    plot = mp2, 
    y = "0.5b",
    fontsize = 8, 
    scale = "Mb",
    params = region
  )
  #> genomeLabel[genomeLabel2]
  
  ## Annotate y-axis
  annoYaxis(
    plot = mp2,
    at = c(0, 2, 4, 6, 8, 10, 12, 14),
    axisLine = TRUE, fontsize = 8
  )
  #> yaxis[yaxis2]
  
  ## Plot y-axis label
  plotText(
    label = "-log10(p-value)", x = -1, y = y.coord.z+2.5, rot = 90,
    fontsize = 8, fontface = "bold", just = "center",
    params = region
  )
  }
  
}

# TEST FUNCTION
#manhattan.plot.function(gwas.file = dir(paste(config$data.dir, config$gwas.dir, sep=""), full.names = TRUE, pattern = config$gwas.ext), 
 #                       Chr = 20, 
  #                      Start = 45841721, 
   #                     End = 45857405, 
    #                    sign.p = 5e-6,
     #                   chr.len.df = chrom.cen.df,
      #                  gwas.names =config$gwas.names)


################### PIECHART OF CATEGORIES FOUND IN CATEGORICAL BED: 

# This function generates a circular packing plot with the categories reported in the categoriacal bed file and their percentage in the whole genome and in the selected range


#library(ggraph)
#library(igraph)
#library(dplyr)
#library(ggplot2)
#library(ggpubr)
categorical.pie.function <- function(cat.file, cat.names, chr, Start, End){
  
  ## Specifiy complete chromosome name
  chrom = paste("chr", chr, sep = "")
  
  ## Prepara data for whole genome plotting
  group <- c()
  subgroup <- c()
  group.sel <- c()
  subgroup.sel <- c()
  vertices.df <- data.frame()
  vertices.sel.df <- data.frame()
  for (i in 1:length(cat.file)){
    # Read cat file
    cat.file.r <- read.table(cat.file[i], header = T, sep= "\t")
    ##### For total genome
    # crate dataframe with hierarchy: cat.name, categories
    subgroup <- c(subgroup, unique(cat.file.r$category))
    group <- c(group, rep(cat.names[i], length(unique(cat.file.r$category))))
    # create datafrane with vertices names and size
    vertices.df <- rbind(vertices.df, as.data.frame(table(cat.file.r$category)))
    # add the leaf vertex with tot size of the group
    vertices.df <- rbind(vertices.df, data.frame(Var1 = cat.names[i], Freq = nrow(cat.file.r)))
    # generate column with percentages
    vertex.perc <- as.data.frame(round(prop.table(table(cat.file.r$category))*100, 0))
    vertices.df$perc <- c(vertex.perc$Freq, 100)
    
    #### For selected region
    # filter the input table based on the selected region
    cat.file.sel <- dplyr::filter(cat.file.r, chr == chrom & start >= Start & end <= End)
    # crate dataframe with hierarchy: cat.name, categories
    subgroup.sel <- c(subgroup.sel, unique(cat.file.sel$category))
    group.sel <- c(group.sel, rep(cat.names[i], length(unique(cat.file.sel$category))))
    # create datafrane with vertices names and size
    vertices.sel.df <- rbind(vertices.sel.df, as.data.frame(table(cat.file.sel$category)))
    # add the leaf vertex with tot size of the group
    vertices.sel.df <- rbind(vertices.sel.df, data.frame(Var1 = cat.names[i], Freq = nrow(cat.file.sel)))
    # generate column with percentages
    vertex.sel.perc <- as.data.frame(round(prop.table(table(cat.file.sel$category))*100, 0))
    vertices.sel.df$perc <- c(vertex.sel.perc$Freq, 100)
  }
  # change colnames vertices
  colnames(vertices.df) <- c("names", "size", "perc")
  colnames(vertices.sel.df) <- c("names", "size", "perc")
  # Merge groups and subgroups in a data frame
  groups.df <- data.frame(group = group,
                         subgroup = subgroup)
  groups.sel.df <- data.frame(group = group.sel,
                          subgroup = subgroup.sel)
  # Generate a 'graph' object with the igraph library
  mygraph <- graph_from_data_frame(groups.df, vertices=vertices.df)
  mygraph.sel <- graph_from_data_frame(groups.sel.df, vertices=vertices.sel.df)
  # Make the plot
  p1 <- ggraph(mygraph, layout = 'circlepack', weight=size) + 
    geom_node_circle(aes(fill = size), color = "white") +
    geom_node_text(aes(label=paste(name, "\n", perc, "%", sep=""), filter = leaf), size = 5, repel = TRUE, color = "black", fontface = "bold") +
    theme_void() + 
    theme(legend.position = "none",
          plot.title = element_text(size = 16, face = "bold")) +
    scale_fill_distiller(palette =  "Blues", direction = 1) +
    ggtitle(label = "Total genome")
  #print(p1)
  if (nrow(groups.sel.df) > 0){
  p2 <- ggraph(mygraph.sel, layout = 'circlepack', weight=size) + 
    geom_node_circle(aes(fill = size), color = "white") +
    geom_node_text(aes(label=paste(name, "\n", perc, "%", sep=""), filter = leaf), size = 5, repel = TRUE, color = "gold", fontface = "bold") +
    theme_void() + 
    theme(legend.position = "none",
          plot.title = element_text(size = 16, face = "bold")) +
    scale_fill_distiller(palette =  "PuOr", direction = 1) +
    ggtitle(label = "Selected region")
  #print(p2)
  
  p <- ggpubr::ggarrange(p1, p2, nrow = 1, ncol = 2)
  print(p)
  } else {
    p <- ggpubr::ggarrange(p1, nrow = 1, ncol = 2)
    print(p)
  }
}



## TEST function
#categorical.pie.function(cat.file = dir(full.names = TRUE, pattern = config$cat.file),
#                         cat.names = config$cat.names,
#                         chr = 21,
 #                        Start = 1,
  #                       End = 1000)


