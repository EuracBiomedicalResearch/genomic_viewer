
## The following script will be used to generate plots for the statistical analysis of peaks and archs graphs

########################################## Barplot of total and selected region peaks number (bed)

basic_statistics_genome_tracks <- function(bed.file, bed.names, chr, Start, End, filetype){
  chrom <- paste0("chr", chr)
  print("Calculating peaks nr")
  # Read bed files and peaks nr
  bed.tab.list <- list() ## Capire se serve davvero storare questa info o se posso evitare
  peaks.nr <- c() # For total nr of peaks
  peaks.nr.sel <- c() # For peaks nr in the selected region
  for (i in 1:length(bed.file)){
    bed.tab <- read_delim(bed.file[i], "\t", col_names = T)
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
    geom_bar(stat="identity", fill="#009999") +
    ggtitle(paste(label, " ",chrom, ":", Start, "-", End, sep="")) +
    ylab(label) +
    xlab("") +
    theme_minimal() +
    theme(text = element_text(size = 10),
          axis.text.y = element_text(size = 10),
          axis.text.x = element_text(size = 10),
          strip.text.x = element_text(size = 10)) +
    geom_text(aes(label=peaks.nr), vjust=1.6, color="white", size=4) +
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
peaks_intersection_venn_function <- function(bed.file, bed.names, bedpe.file, bedpe.names, chr, Start, End, genome){
  print("Calculating peaks overlaps upset")
  # Convert BED AND bedpe to GRanges:
    # BEDPE files are imported as object of class Paires, which is a double GRanges. Therefore to merge it into a single GRanges object a further step is needed with the spiky lib
 
  q=GRanges(seqnames=paste("chr", chr, sep=""),
            ranges=IRanges(start = Start, end = End))
  
  if (!is.null(bed.file) & length(bed.file) > 0){
   bed.peaks.list <- list()
   bed.peaks.list.s <- list()
    for (i in 1:length(bed.file)){
      bed.peaks.list[[i]] <- import(bed.file[i], format = "BED", genome = genome, colnames = c("chrom", "start", "end"))
      bed.peaks.list.s[[i]] <- subsetByOverlaps(bed.peaks.list[[i]], q)
      }
  } else {
    bed.peaks.list <- list()
    bed.peaks.list.s <- list()
    bed.names <- NULL
  }
  
  if (!is.null(bedpe.file) & length(bedpe.file) > 0){
    bedpe.peaks.list <- list()
    bedpe.peaks.list.s <- list()
      for (i in 1:length(bedpe.file)){
        bedpe.peaks.list[[i]] <- spiky::convertPairedGRtoGR(import(bedpe.file[i], format = "bedpe", genome = genome))
        bedpe.peaks.list.s[[i]] <- subsetByOverlaps(bedpe.peaks.list[[i]], q)
      }
  } else {
    bedpe.peaks.list <- list()
    bedpe.peaks.list.s <- list()
    bedpe.names <- NULL
    }
  
  peaklist <-  c(bed.peaks.list, bedpe.peaks.list)
  names(peaklist) <- names <- c(bed.names, bedpe.names)
  ups <- overlap_upset_plot(peaklist = peaklist, verbose = T)


  peaklist2 <- c(unlist(bed.peaks.list.s), bedpe.peaks.list.s)
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
peaks.annotation.function <- function(bed.file, bed.names, genome){
  print("Calculating peaks annotation")
  ## Start of function
  if (genome %in% c("hg19", "hg38", "T2T")){
    org <- "Hsapiens"
  } else if (genome %in% c("mm10", "mm39")){
    org <- "Mmusculus"
  }
anno.plot.list <- list()
for (i in 1:length(bed.file)){
  anno.p <- genomicElementDistribution(import(bed.file[i], format = "BED", genome = genome), 
                                       TxDb = get(paste("TxDb.", org, ".UCSC.", genome, ".knownGene", sep="")))
  anno.plot.list[[i]] <- anno.p$plot
}

ggpubr::ggarrange(plotlist = anno.plot.list, nrow = ceiling(length(anno.plot.list)/3), labels = bed.names)
  ## End of function
}


########################################## FUNCTION TO GENERATE A MANHATTAN PLOT ON THE SELECTED CHROMOSOME AND ZOOM-IN REGION WITH SNPs NAMES

manhattan.plot.function <- function(gwas.file, Chr, start, end, sign.p, chr.len.df, gwas.names, genome){
  ## required libraries:
  # library(TxDb.Hsapiens.UCSC.hg38.knownGene)
  # library(plotgardener)
  # library(paletteer)
  # library(dplyr)
  print("Calculating manhattan plot")
  ## Specifiy complete chromosome name
  chr = paste("chr", Chr, sep = "")
  ## Retrieve chromosome length for plotting
  chr.len <- chr.len.df$chr.len[chr.len.df$chr == chr]
  ## Define page height
  h <- 6*length(gwas.file)*2
  
  ## Define plotting parameters for whole chromosome
  params <- pgParams(
    chrom = chr, chromstart = 1, chromend = chr.len,
    assembly = genome,
    x = 0, just = c("left", "bottom"),
    width = 12, length = 12, height = 6, default.units = "cm"
  )
  
  ## Define plotting parameter for zoom-in region
  region <- pgParams(
    chrom = chr, chromstart = start, chromend = end,
    assembly = genome,
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
    man.data.t <- read_delim(gwas.file[i], "\t", col_names = T)
    
    ## Define lead SNPs to be plotted wit their name specified
    leadSNP <- filter(man.data.t, chrom == chr & p < sign.p) %>% dplyr::arrange(p)
    
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
      lty = 2, #range = c(0, NA),
      y = "0b",
      default.units = "cm",
      params = params
    )
    ## Annotate signifcant SNPs
    if(nrow(leadSNP) > 0 & nrow(leadSNP) <= 10){
    plotText(label = leadSNP$snp, 
             x = leadSNP$pos*(12/chr.len) + 0.2 ,  
             y = h - ((-log10(leadSNP$p)*(y.coord-5.99))/-log10(min(leadSNP$p))), #äy = y.coord-(-log10(leadSNP$p)*6/14), 
             check.overlap = T,
             repel = T,
             params = params,
             rot = 35,
             fontsize = 8)
    } else if (nrow(leadSNP) > 10){
      plotText(label = leadSNP$snp[1:10], 
               x = leadSNP$pos[1:10]*(12/chr.len) + 0.2 , 
               y = h- ((-log10(leadSNP$p[1:10])*(y.coord-5.99))/-log10(min(leadSNP$p[1:10]))), 
               check.overlap = T,
               repel = T,
               params = params,
               rot = 35,
               fontsize = 8)
    }
    #print(h-((-log10(leadSNP$p)*(y.coord-5.99))/-log10(min(leadSNP$p))))
  
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
    #at = seq(0, 40, by = 10),
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
    man.data.t <- read_delim(gwas.file[i], "\t", col_names = T)
    
    ## Define lead SNPs to be plotted wit their name specified
    leadSNP <- filter(man.data.t, chrom == chr & p < sign.p) %>% dplyr::arrange(p)
    
    ## Create Manhattan plot of the selected chromosome
    mp2 <- plotManhattan(
      data = man.data.t,
      fill = colorby("p", palette = colorRampPalette(paletteer_c("grDevices::Plasma", 30))),
      trans = "-log10",
      sigVal = sign.p, sigLine = TRUE, sigCol = "#7ecdbb",  col = "grey",
      lty = 2, range = c(0, 40),
      y = y.coord.z,
      default.units = "cm",
      params = region,
      label = "zoom"
    )
    
    y.coord.z <- y.coord.z - 6
    ## Annotate significant SNPs
    if(nrow(leadSNP) > 0 & nrow(leadSNP) <= 10){
      plotText(label = leadSNP$snp, 
               x = leadSNP$pos*(12/chr.len) + 0.2 ,  
               y = h - ((-log10(leadSNP$p)*(y.coord.z-5.99))/-log10(min(leadSNP$p))), 
               check.overlap = T,
               repel = T,
               params = params,
               rot = 35,
               fontsize = 8)
    } else if (nrow(leadSNP) > 10){
      plotText(label = leadSNP$snp[1:10], 
               x = leadSNP$pos[1:10]*(12/chr.len) + 0.2 , 
               y = h- ((-log10(leadSNP$p[1:10])*(y.coord.z-5.99))/-log10(min(leadSNP$p[1:10]))), 
               check.overlap = T,
               repel = T,
               params = params,
               rot = 35,
               fontsize = 8)
    }
    
     
    
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
    at = seq(0, 40, by = 10),
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
  #                      start = 45841721, 
   #                     end = 45857405, 
    #                    sign.p = 5e-6,
     #                   chr.len.df = chrom.cen.df,
      #                  gwas.names =config$gwas.names)


################### PIECHART OF CATEGORIES FOUND IN CATEGORICAL BED: 

# This function generates a circular packing plot with the categories reported in the categorical bed file and their percentage in the whole genome and in the selected range


#library(ggraph)
#library(igraph)
#library(dplyr)
#library(ggplot2)
#library(ggpubr)
categorical.pie.function <- function(cat.file, cat.names, chr, Start, End){
  print("Calculating categorical pie")
  ## Specifiy complete chromosome name
  chrom = paste("chr", chr, sep = "")
  plots <- list()
  for (i in 1:length(cat.file)){
    ## Prepara data for whole genome plotting
    # Read cat file
    cat.file.r <- read_delim(cat.file[i], "\t", col_names = T) #, col_select = c(1,2,3, 'category')
    ##### For total genome
    # crate dataframe with hierarchy: cat.name, categories
    subgroup <- unique(cat.file.r$category)
    group <- rep(cat.names[i], length(unique(cat.file.r$category)))
    # create dataframe with vertices names and size
    vertices.df <- as.data.frame(table(cat.file.r$category))
    # add the leaf vertex with tot size of the group
    vertices.df <- rbind(vertices.df, data.frame(Var1 = cat.names[i], Freq = nrow(cat.file.r)))
    # generate column with percentages
    vertices.df$perc <- c(as.data.frame(round(prop.table(table(cat.file.r$category))*100, 0))$Freq, 100)
    
    #### For selected region
    # filter the input table based on the selected region
    cat.file.sel <- dplyr::filter(cat.file.r, chr == chrom & start >= Start & end <= End)
    # crate dataframe with hierarchy: cat.name, categories
    subgroup.sel <- unique(cat.file.sel$category)
    group.sel <- rep(cat.names[i], length(unique(cat.file.sel$category)))
    # create datafrane with vertices names and size
    vertices.sel.df <- as.data.frame(table(cat.file.sel$category))
    # add the leaf vertex with tot size of the group
    vertices.sel.df <- rbind(vertices.sel.df, data.frame(Var1 = cat.names[i], Freq = nrow(cat.file.sel)))
    # generate column with percentages
    vertices.sel.df$perc <- c(as.data.frame(round(prop.table(table(cat.file.sel$category))*100, 0))$Freq, 100)

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
    geom_node_label(aes(label=paste(name, ": ", perc, "%", sep=""), filter = leaf), label.padding = unit(0.1, "lines"), size = 4, repel = TRUE, color = "grey21", fontface = "bold") +
    theme_void() + 
    theme(legend.position = "none",
          plot.title = element_text(size = 16, face = "bold")) +
    scale_fill_distiller(palette =  "Blues", direction = 1) +
    ggtitle(label = "Total genome")
  #print(p1)
  if (nrow(groups.sel.df) > 0){
  p2 <- ggraph(mygraph.sel, layout = 'circlepack', weight=size) + 
    geom_node_circle(aes(fill = size), color = "white") +
    geom_node_label(aes(label=paste(name, ": ", perc, "%", sep=""), filter = leaf), label.padding = unit(0.1, "lines"), size = 4, repel = TRUE, color = "grey21", fontface = "bold") +
    theme_void() + 
    theme(legend.position = "none",
          plot.title = element_text(size = 16, face = "bold")) +
    scale_fill_distiller(palette =  "PuOr", direction = 1) +
    ggtitle(label = "Selected region")
  #print(p2)
  
  p <- ggpubr::ggarrange(p1, p2, nrow = 1, ncol = 2)
  #print(p)
  } else {
    p <- ggpubr::ggarrange(p1, nrow = 1, ncol = 2)
    #print(p)
  }
  plots[[i]] <- p
  #print(plots[[i]])
  }
  
  # define nr of columns for final plot
  if(length(cat.file) <= 9){
    n.col =  3
    n.row = 2
  } else {
    n.col  =  6
    n.row = 4
  }
  p.final <- ggpubr::ggarrange(plotlist=plots, nrow = n.row, ncol = n.col, labels = cat.names, label.y = 0.9, font.label = list(face = "italic", size = 12))
  print(p.final)
}



## TEST function
#categorical.pie.function(cat.file = cat.file, #dir(full.names = TRUE, pattern = config$cat.file),
 #                        cat.names = config$cat.names,
  #                       chr = 21,
   #                      Start = 1,
    #                     End = 1000)


################### CIRCOS PLOT FROM BEDPE FILE

# This function is used to generate a circos plot from the 3D contacts stored in the bedpe file. the 7th column of the bedpe file must contain a score value
  # Used libraries:
  #library(circlize)
  #library(readr)
  #library(dplyr)
  #library(paletteer)

# Test function 
#circos.function(bedpe.file = bedpe.file, 
 #               chromosome = 1,
  #              genome = "hg38",
   #             zoom_start = 2800000,
    #            zoom_end = 2850000,
     #           genes.label =  read_delim("C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/hgnc_symbols/hg38_gene_symbol_cleaned.bed", "\t", col_names = T, show_col_types = F),
      #          bedpe.names = "test")

circos.function <- function(bedpe.file, chromosome, genome, zoom_start, zoom_end, genes.label, bedpe.names, cytoband.ext){
  
  col <- c(paletteer_d("ggthemr::flat"), paletteer_d("ggthemes::gdoc"),paletteer_d("ggthemes::excel_Atlas") )
  names(col) <- paste("chr", c(1:22, "X", "Y"), sep="")
  chrom = paste("chr", chromosome, sep="")
  
  ##### READING FILES #####
  # read cytoband, common for all bedpe
  if ( genome != "T2T"){
  cytoband = read.cytoband(species = genome, chromosome.index = chrom)
  cytoband.bed <- cytoband$df
  } else {
    cytoband.bed <-  cytoband.ext
    colnames(cytoband.bed) <- c("V1", "V2", "V3", "V4", "V5")
  }
  # bed of genes annotation hg38, common for all bedpe
  genes.ann <- genes.label
  genes.ann$chromosome_name <- paste("chr", genes.ann$chromosome_name, sep="") # add complete name to chr
  ## calculate gene density from the selected chromosome
  genes.density.bed <- c()
  for (i in 1:nrow(cytoband.bed)){
    start <- cytoband.bed$V2[i]
    end <- cytoband.bed$V3[i]
    genes.ann.chr <- dplyr::filter(genes.ann, chromosome_name == chrom)
    genes.density.bed <- c(genes.density.bed, length(which(genes.ann.chr$start_position >= start & genes.ann.chr$end_position <= end)))
  }
  cytoband.bed$value <- genes.density.bed

  genes.ann <- dplyr::filter(genes.ann, chromosome_name == chrom & start_position >= zoom_start & end_position <= zoom_end) # filter just genes in the zoom region
  genes.ann$chromosome_name <- paste("zoom_", genes.ann$chromosome_name, sep="") # add zoo to the chromosome name
  
  # Arrange the layout of the resulting image that may combine multiple plots based on the number of input bedpe files
  layout(matrix(1:length(bedpe.file), length(bedpe.file), 2)) 
  
  # for every separate bedpe
  for (i in 1:length(bedpe.file)){
  # Read contacts for entire genome
  bed1 <- read_delim(bedpe.file[i], col_select = c(1,2,3), col_names = F)
  bed2 <- read_delim(bedpe.file[i], col_select = c(4,5,6), col_names = F)
  # bedpe of the zoomed region
  bedpe.zoom <- read_delim(bedpe.file[i], col_names = F) %>% dplyr::filter( X1 == chrom & X2 >= zoom_start & X4 == chrom & X6 <= zoom_end)
  bedpe.zoom[, c(1,4)] <- paste("zoom_", chrom, sep="")
  
  
  
  ##### PLOT ENTIRE CHROMOSOME #####
  circos.clear()
  col_text <- "grey40"
  circos.par("track.height"=0.8, gap.degree=5, cell.padding=c(0, 0, 0, 0))
  ## initialize ideogram
  if (genome != "T2T"){
  circos.initializeWithIdeogram(species = genome, chromosome.index = chrom, plotType = c("ideogram"))
  ## add label for genomic position
  brk <- seq(from = 1, to= cytoband$chr.len, length.out=50)
  } else {
    circos.initializeWithIdeogram(cytoband = as.data.frame(cytoband.bed), chromosome.index = chrom, plotType = c("ideogram"))
    ## add label for genomic position
    brk <- seq(from = 1, to= max(cytoband.bed$V3[which(cytoband.bed$V1 == chrom)]), length.out=50)
  }
  circos.track(track.index = get.current.track.index(), panel.fun=function(x, y) {
    circos.axis(h="top", major.at=brk, labels=round(brk/10^6, 1), labels.cex=0.7, 
                col=col_text, labels.col=col_text, lwd=0.7, labels.facing="clockwise")
  }, bg.border=F)
  ## plot contact density
  if (genome %in% c("hg19", "hg38", "T2T")){
    track.h = 0.05
  } else { track.h = 0.015  }
  bed <- data.frame(chr = cytoband.bed$V1, start = cytoband.bed$V2, end = cytoband.bed$V3, value = log10(cytoband.bed$value+1))
  circos.genomicTrackPlotRegion(bed, ylim = range(bed$value), bg.border = NA, panel.fun = function(region, value, ...) {
    circos.genomicLines(region, value, area = TRUE, border = NA, baseline = 0, col = col[chrom])
  }, track.height = track.h) 
  ## plot contacts arches on the whole chromosome
  circos.genomicLink(region1 = bed1, region2 = bed2, h = 0.1, col = col[chrom])
  ## add link across sectors
  circos.link(chrom, point1 = c(zoom_start, zoom_end),
              chrom, point2 = c(zoom_start, zoom_end), 
              col = "#00000020", border = NA, h = 0.205, w =0.1)
  
  circos.clear()
  
  ##### PLOT ZOOM CHROMOSOME #####
  par(mar = c(0, 0, 0, 0), new = TRUE)
  ## initialize zoom genomic region    
  circos.par("canvas.xlim" = c(-0.1, 0.1), "canvas.ylim" = c(-2.1, 2.1), clock.wise = FALSE,
             cell.padding = c(0, 0, 0, 0), gap.degree = 5, start.degree = 92.5)
  circos.genomicInitialize(data.frame(chr = paste("zoom_", chrom, sep=""), start = zoom_start, end = zoom_end), plotType = NULL)
  ## add label of genomic bp
  brk.zoom <- seq(from = zoom_start, to= zoom_end, length.out=20)
  circos.track(track.index = 1, ylim = c(0,1), panel.fun=function(x, y) {
    circos.axis(h="top", major.at=brk.zoom, labels=round(brk.zoom/10^6, 1), labels.cex=0.6, 
                col=col_text, labels.col=col_text, lwd=0.7, labels.facing="clockwise")
  }, bg.border=F)
  ## Add gene label annotation
  circos.genomicLabels(genes.ann, labels.column=5,  cex=0.4, col=col_text, line_lwd=0.5, line_col="grey80", 
                       side="outside", connection_height=0.05, labels_height=0.01, niceFacing = T, track.margin = c(0,0.2))
  ## add contact arches of the zoom region
  circos.genomicLink(region1 = bedpe.zoom[, c(1,2,3)], region2= bedpe.zoom[, c(4,5,6)], h = 0.2, col = "dodgerblue")
  ## add sector highlight
  highlight.sector(sector.index = paste("zoom_", chrom, sep=""),col = "#00000020")
  # add chromosome name in the center of the plot
  text(0, 0, paste(chrom, "\n", bedpe.names[i], sep=""), cex = 1, col = col_text)
  circos.link(paste("zoom_", chrom, sep=""), point1 = c(zoom_start, zoom_end),
              paste("zoom_", chrom, sep=""), point2 = c(zoom_start, zoom_end), 
              col = "#00000020", border = NA, h = 0.205, w =0.1)
  
  circos.clear() 
  }
}
