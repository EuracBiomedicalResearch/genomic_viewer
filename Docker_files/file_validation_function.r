#### Functions to check input file formats


########### ------ COMMON FUNCTIONS
## Define a common return format  
validationResult <- function(errors = character()) {
  list(
    valid = length(errors) == 0,
    errors = errors
  )
}

## Check extension
checkExtension <- function(path, extensions) {
  
  ext <- tolower(tools::file_ext(path))
  
  if (!(ext %in% tolower(extensions))) {
    
    return(
      sprintf("Expected extension: %s",
        paste(extensions, collapse = ", ")
      )
    )
  }
  NULL
}

## Readability check
readPreview <- function(path,
                        col_names = TRUE,
                        n = 10) {
  tryCatch(
    readr::read_tsv(
      path,
      col_names = col_names,
      n_max = n,
      show_col_types = FALSE,
      name_repair = "minimal",
      progress = FALSE,
    ),
    error = function(e) NULL
  )
}

## Global validation function
checkFiles <- function(files, validator) {
  all.errors <- character()
  if (length(files) == 0)
    return(all.errors)
  for (file in files) {
    res <- validator(file)
    if (!res$valid) {
      all.errors <- c(all.errors, paste0("\nFile: ", basename(file), "\n", paste("  -", res$errors, collapse = "\n")))
    }
  }
 
  return(all.errors)
}


########### ------ BED VALIDATOR FUNCTION

validateBed <- function(path) {
  errors <- character()
  # Check extension
  err <- checkExtension(path, c("bed", "txt", "tsv"))
  if (!is.null(err))
    errors <- c(errors, err)
  # Check readability 
  bed <- readPreview(path,
                     col_names = FALSE)
  
  if (is.null(bed))
    return(validationResult(
      c(errors,
        "Cannot read the BED file.")
    ))
  
  # Check number of columns before accessing them
  if (ncol(bed) < 3) {
    errors <- c(errors,
                "BED requires at least three columns.")
    return(validationResult(errors))
  }
  
  if (tolower(as.character(bed[[1]][1])) %in%
      c("chr","chromosome", "chrom"))
    errors <- c(errors,
                "BED files must not contain a header.")
  
  if (!all(startsWith(as.character(bed[[1]]), "chr")))
    errors <- c(errors,
                "Chromosome names must start with 'chr'.")
  
  if (!is.numeric(bed[[2]]))
    errors <- c(errors,
                "Column 2 must be numeric.")
  
  if (!is.numeric(bed[[3]]))
    errors <- c(errors,
                "Column 3 must be numeric.")
  
  if (any(bed[[2]] > bed[[3]]))
    errors <- c(errors,
                "Chromosome start must not exceed chromosome end")
  
  validationResult(errors)
  
}

########### ------ CATEGORICAL BED VALIDATOR FUNCTION

validateCategoricalBed <- function(path) {
  errors <- character()
  # Check extension
  err <- checkExtension(path,
                        c("bed", "txt", "tsv"))
  
  if (!is.null(err))
    errors <- c(errors, err)
  # Check if file readable
  bed <- readPreview(path)
  
  if (is.null(bed))
    return(validationResult(c(errors,
                              "Cannot read the file.")))
  # Check required columns
  required <- c(
    "chr",
    "start",
    "end",
    "category"
  )
  missing <- setdiff(required, names(bed))
  if (length(missing))
    errors <- c(errors,
                paste(
                  "Missing required columns:",
                  paste(missing, collapse = ", ")
                ))
  # Check correct format
  if (!all(startsWith(
    as.character(bed$chr),
    "chr")))
    errors <- c(errors,
                "Chromosome names must start with 'chr'.")
  
  if (!is.numeric(bed$start))
    errors <- c(errors,
                "Start coordinate must be numeric.")
  
  if (!is.numeric(bed$end))
    errors <- c(errors,
                "End coordinate must be numeric.")
  
  if (any(bed$start > bed$end))
    errors <- c(errors,
                "Chromosome start must not exceed chromosome end")
  
  validationResult(errors)
}

########### ------ GWAS VALIDATOR FUNCTION

validateGWAS <- function(path) {
  errors <- character()
  # check file extension
  err <- checkExtension(path,
                        c("tsv", "txt", "gz"))
  if (!is.null(err))
    errors <- c(errors, err)
  # check if readable
  gwas <- readPreview(path)
  if (is.null(gwas))
    return(validationResult(c(errors,
                              "Cannot read the GWAS file.")))
  # check required columns
  required <- c("chrom", "pos", "p", "snp")
  names(gwas) <- tolower(trimws(names(gwas)))
  missing <- setdiff(required,
                     names(gwas))
  
  if (length(missing))
    errors <- c(errors,
                paste(
                  "Missing required columns:",
                  paste(missing,
                        collapse = ", ")
                ))
  
  if ("chrom" %in% names(gwas))
    if (!all(startsWith(as.character(gwas$chrom), "chr")))
      errors <- c(errors,
                  "Chromosome names must start with 'chr'.")
  
  if ("pos" %in% names(gwas))
    if (!is.numeric(gwas$pos))
      errors <- c(errors,
                  "'pos' must be numeric.")
  
  if ("p" %in% names(gwas))
    if (!is.numeric(gwas$p))
      errors <- c(errors,
                  "'p' must be numeric.")
  validationResult(errors)
}


########### ------ BIGWIG VALIDATOR FUNCTION

validateBigWig <- function(path) {
  errors <- character()
  # check extension
  err <- checkExtension(path,
                        c("bw", "bigwig"))
  if (!is.null(err))
    errors <- c(errors, err)
  # check readability
  ok <- tryCatch({
    rtracklayer::BigWigFile(path)
    TRUE
  }, error = function(e) FALSE)
  
  if (!ok)
    errors <- c(errors,
                "The file is not a valid bigWig file.")
  validationResult(errors)
}

########### ------ BAM VALIDATOR FUNCTION

validateBam <- function(path) {
  errors <- character()
  # check extension
  err <- checkExtension(path, "bam")
  if (!is.null(err))
    errors <- c(errors, err)
  # check file index
  bai <- paste0(path, ".bai")
  if (!file.exists(bai))
    errors <- c(errors,
                "The BAM index (.bai) file is missing.")
  # check readability
  ok <- tryCatch({
    Rsamtools::BamFile(path)
    TRUE
  }, error = function(e) FALSE)
  
  if (!ok)
    errors <- c(errors,
                "The BAM file cannot be opened.")
  validationResult(errors)
}

########### ------ HIC VALIDATOR FUNCTION

validateHic <- function(path) {
  errors <- character()
  # check extension
  err <- checkExtension(path, "hic")
  if (!is.null(err))
    errors <- c(errors, err)
  # check readability and content
  chroms <- tryCatch(
    strawr::readHicChroms(path),
    error = function(e) NULL
  )
  
  if (is.null(chroms)) {
    errors <- c(errors,
                "The file is not a valid HiC file.")
  } else if (nrow(chroms) == 0) {
    errors <- c(errors,
                "The HiC file contains no chromosome information.")
  }
  validationResult(errors)
}


########### ------ BEDPE VALIDATOR FUNCTION

validateBedpe <- function(path) {
  errors <- character()
  # Check file extension
  err <- checkExtension(path,
                        c("bedpe", "txt", "tsv"))
  
  if (!is.null(err))
    errors <- c(errors, err)
  # check if file readable
  bedpe <- readPreview(path,
                       col_names = FALSE)

  if (is.null(bedpe))
    return(validationResult(c(errors,
                              "Cannot read the BEDPE file.")))
  
  # Minimum columns
  if (ncol(bedpe) < 6) {
    errors <- c(errors,
                "BEDPE files must contain at least six columns.")
    return(validationResult(errors))
  }
  
  # Check presence of optional header
  checkHeader <- function(row) {
    if (length(row) < 6)
      return(FALSE)
    # check if chromosome columns are formatted well
    chrA <- startsWith(as.character(row[[1]]), "chr")
    chrB <- startsWith(as.character(row[[4]]), "chr")
    # check if coordinates are numeric
    coords <- suppressWarnings(as.numeric(c(row[[2]], row[[3]], row[[5]], row[[6]])))
    
    if (chrA & chrB & !any(is.na(coords))) {
      return(TRUE)
    } else {return(FALSE)}
  }
  
  if (nrow(bedpe) >= 2) {
    first.valid <- checkHeader(bedpe[1, ])
    second.valid <- checkHeader(bedpe[2, ])
    # if first row fails but second works assume header
    if (!first.valid & second.valid) {
      bedpe <- bedpe[-1, ]
    }
  }
    # If after header removal no data remains
  if (nrow(bedpe) == 0)
    return(validationResult(c(errors,
                              "BEDPE file contains no valid data rows.")))
  
  # Check format of chrom after fixing optional header
  if (ncol(bedpe) >= 1 & !all(startsWith(as.character(bedpe[[1]]), "chr")))
    errors <- c(errors,
                "Column 1 must contain chromosome names.")
  
  if (ncol(bedpe) >= 4 & !all(startsWith(as.character(bedpe[[4]]), "chr")))
    errors <- c(errors,
                "Column 4 must contain chromosome names.")
  
  # Check coordinates are numeric
  numericCols <- c(2, 3, 5, 6)
  for (i in numericCols) {
    values <- suppressWarnings(as.numeric(bedpe[[i]]))
    if (any(is.na(values))) {
      errors <- c(errors,
                  paste("Column", i, "must be numeric."))
    }
  }
  
  # Check coordinates
  if (ncol(bedpe) >= 6) {
    
    if (is.numeric(bedpe[[2]]) & is.numeric(bedpe[[3]]) & any(bedpe[[2]] > bedpe[[3]])) {
      errors <- c(errors,
                  "BEDPE first interval has start greater than end.")
    }
    
    if (is.numeric(bedpe[[5]]) & is.numeric(bedpe[[6]]) & any(bedpe[[5]] > bedpe[[6]])) {
      errors <- c(errors,
                  "BEDPE second interval has start greater than end.")
    }
    
    if (is.numeric(bedpe[[2]]) & is.numeric(bedpe[[5]]) & any(bedpe[[2]] > bedpe[[5]])) {
      errors <- c(errors,
                  "BEDPE intervals are not ordered: first anchor should precede second anchor.")
    }
  }
  validationResult(errors)
}

########### ------ REGION TABLE VALIDATOR FUNCTION

validateRegionFile <- function(path) {
  errors <- character()
  # check file extension
  err <- checkExtension(path,
                        c("txt", "tsv", "bed"))
  if (!is.null(err))
    errors <- c(errors, err)
  # check if file readable
  reg <- readPreview(path,
                     col_names = FALSE)
  
  if (is.null(reg))
    return(validationResult(c(
      errors,
      "Cannot read the region file."
    )))
  
  if (ncol(reg) < 3) {
    errors <- c(errors,
                "Region files must contain at least three columns.")
    return(validationResult(errors))
  }
  
  if (ncol(reg) > 6)
    errors <- c(errors,
                "Region files can contain at most six columns.")
  
  if (ncol(reg) >= 1) {
    if (!all(startsWith(as.character(reg[[1]]), "chr")))
      errors <- c(errors,
                  "Column 1 must contain chromosome names starting with 'chr'.")
  }
  
  if (ncol(reg) >= 2) {
    if (!is.numeric(reg[[2]]))
      errors <- c(errors,
                  "Column 2 (start) must be numeric.")
  }
  
  if (ncol(reg) >= 3) {
    if (!is.numeric(reg[[3]]))
      errors <- c(errors,
                  "Column 3 (end) must be numeric.")
  }
  
  if (ncol(reg) >= 3 & is.numeric(reg[[2]]) & is.numeric(reg[[3]])) {
    if (any(reg[[2]] > reg[[3]]))
      errors <- c(errors,
                  "Start coordinates cannot be larger than end coordinates.")
  }
  validationResult(errors)
}

## Run different validation function if the file provided to bed.file is .bed or .bam
validateBedOrBam <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "bam") {
    return(validateBam(path))
  } else {
    return(validateBed(path))
  }
}
