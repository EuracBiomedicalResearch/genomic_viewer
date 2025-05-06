
## Function for reading data tables and visualize them in the "Data" tabset of plotgardenere Shiny app:

library(dplyr)
shiny_read_table_function <- function(bed.file, bedpe.file, gwas.file, chr, start, end){
  
  chrom <- paste0("chr", chr)
  
  # Read bed files
  bed.tab.list <- list()
  if(length(bed.file) > 0){
    for (i in 1:length(bed.file)){
      bed.tab <- read.table(bed.file[i], header = F, sep= "\t")
     colnames(bed.tab)[1:3] <- c("chr", "start", "end")
     bed.tab <- dplyr::filter(bed.tab, chr == chrom & start >= start & end <= end)
      bed.tab.list[[i]] <- bed.tab
    } 
  } else {bed.tab.list[[1]] <- data.frame(chr = "", start = "", end ="")
    }
  
  # Read bedpe files
  bedpe.tab.list <- list()
  if(length(bedpe.file) > 0){
    for (i in 1:length(bedpe.file)){
     bedpe.tab <- read.table(bedpe.file[i], header = F, sep= "\t")
     colnames(bedpe.tab)[1:6] <- c("chrA", "startA", "endA", "chrB", "startB", "endB")
     bedpe.tab <- dplyr::filter(bedpe.tab, chrA == chrom & startA >= start & endA <= end | chrB == chrom & startB >= start & endB <= end) # This way all the interactions that START or ENDS UP in the selected region will be give even if they STARt or FINISH outside of the rgion, to restrict this parameter you can substitute | with & between the two A and B conditions.
      bedpe.tab.list[[i]] <- bedpe.tab
    }
  } else {bedpe.tab.list[[1]] <- data.frame(chrA = " ", startA = " ", endA =" ", chrB = " ", startB = " ", endB =" ")
    }
  
  # Read gwas files
  gwas.tab.list <- list()
  if(length(gwas.file) > 0){
   for (i in 1:length(gwas.file)){
      gwas.tab <- read.table(gwas.file[i], header = T, sep= "\t")
      gwas.tab <- dplyr::filter(gwas.tab, chrom == chrom & pos >= start & pos <= end) # This way all the SNPs in the selected range will be kept.
     gwas.tab.list[[i]] <- gwas.tab
   }
  } else {gwas.tab.list[[1]] <- data.frame(chrom = "", pos = "", p ="", snp = "")
    }
  
  out.list <- list(bed.tab.list, bedpe.tab.list, gwas.tab.list)
  
  return(out.list)
}

