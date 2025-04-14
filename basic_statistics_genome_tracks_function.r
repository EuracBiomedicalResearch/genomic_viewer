
## The following script will be used to generate plots for the statistical analysis of peaks and archs graphs

########################################## Barplot of total and selected region peaks number (bed)

basic_statistics_genome_tracks <- function(bed.file, bed.names, chr, start, end, filetype){
  
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
    bed.tab.s <- dplyr::filter(bed.tab, chr == chrom & start >= start & end <= end)
    label <- "Peaks nr"
    } else if (filetype == "bedpe"){
      colnames(bed.tab)[1:6] <- c("chrA", "startA", "endA", "chrB", "startB", "endB")
      bed.tab.s <- dplyr::filter(bed.tab, chrA == chrom & startA >= start & endA <= end | chrB == chrom & startB >= start & endB <= end)
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
    ggtitle(paste(label, " ",chrom, ":", start, "-", end, sep="")) +
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
peaks_intersection_venn_function <- function(bed.file, bed.names, bedpe.file, bedpe.names, chr, start, end){
  
  # Convert BED AND bedpe to GRanges:
    # BEDPE files are imported as object of class Paires, which is a double GRanges. Therefore to merge it into a single GRanges object a further step is needed with the spiky lib
 
  q=GRanges(seqnames=paste("chr", chr, sep=""),
            ranges=IRanges(start = start, end = end))
  
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
  ups2 <- overlap_upset_plot(peaklist = peaklist2, verbose = T)
  
  ggpubr::ggarrange(ups$plot, ups2$plot, ncol = 2, nrow=1, labels = c("total", "selected"))
  
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



