
## Function for reading data tables and visualize them in the "Data" tabset of plotgardenere Shiny app:

#library(dplyr)
#library(readr)
shiny_read_table_function <- function(bed.file, bedpe.file, cat.file, gwas.file, chr, Start, End){

  chrom <- paste0("chr", chr)

  # Read bed files
  bed.tab.list <- list()
  if(length(bed.file) > 0){
    for (i in 1:length(bed.file)){
      bed.tab <- read_delim(
        bed.file[i], "\t", col_names = FALSE,
        col_types = list(X2 = col_integer(), X3 = col_integer()) )
     colnames(bed.tab)[1:3] <- c("chr", "start", "end")
     bed.tab <- dplyr::filter(bed.tab, chr == chrom & start >= Start & end <= End)
     bed.tab.list[[i]] <- bed.tab
    }
  } else {
    bed.tab.list[[1]] <- data.frame(chr = "", start = "", end ="")
  }

  # Read bedpe files
  bedpe.tab.list <- list()
  if(length(bedpe.file) > 0){
    for (i in 1:length(bedpe.file)){
     bedpe.tab <- read_delim(
       bedpe.file[i], "\t", col_names = FALSE,
       col_types = list(X2 = col_integer(), X3 = col_integer(),
                        X5 = col_integer(), X6 = col_integer()) )
     colnames(bedpe.tab)[1:6] <- c("chrA", "startA", "endA", "chrB", "startB",
                                   "endB")
     # This way all the interactions that START or ENDS UP in the selected
     # region will be give even if they STARt or FINISH outside of the rgion,
     # to restrict this parameter you can substitute | with & between the
     # two A and B conditions.
     bedpe.tab <- dplyr::filter(
       bedpe.tab,
       chrA == chrom & startA >= Start & endA <= End |
         chrB == chrom & startB >= Start & endB <= End)
      bedpe.tab.list[[i]] <- bedpe.tab
    }
  } else {
    bedpe.tab.list[[1]] <- data.frame(chrA = " ", startA = " ", endA =" ",
                                      chrB = " ", startB = " ", endB =" ")
  }

  # Read categorical bed files
  cat.tab.list <- list()
  if(length(cat.file) > 0){
    for (i in 1:length(cat.file)){
      cat.tab <- read_delim(cat.file[i], "\t", col_names = TRUE,
                            col_types = list(start = col_integer(),
                                             end = col_integer()) )
      cat.tab <- dplyr::filter(cat.tab,
                               chr == chrom & start >= Start & end <= End)
      cat.tab.list[[i]] <- cat.tab
    }
  } else {
    cat.tab.list[[1]] <- data.frame(chr = "", start = "", end ="")
  }


  # Read gwas files
  gwas.tab.list <- list()
  if(length(gwas.file) > 0){
    in.chrom <- chrom
   for (i in 1:length(gwas.file)){
      gwas.tab <- read_delim(gwas.file[i],"\t", col_names = TRUE,
                             col_types = list(pos = col_integer(),
                                              p = col_double()))
      # This way all the SNPs in the selected range will be kept.
      gwas.tab <- dplyr::filter(gwas.tab,
                                chrom == in.chrom & pos >= Start & pos <= End)
      gwas.tab$p <- format(gwas.tab$p, scientific = T)
     gwas.tab.list[[i]] <- gwas.tab
   }
  } else {
    gwas.tab.list[[1]] <- data.frame(chrom = "", pos = "", p ="", snp = "")
  }

  out.list <- list(bed.tab.list, bedpe.tab.list, cat.tab.list, gwas.tab.list)

  return(out.list)
}

