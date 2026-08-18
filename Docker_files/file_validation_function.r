#### Functions to check input file formats
## Error messages
E_FOPEN <- "Cannot open file."
E_BED_MIN3COL <- "BED requires at least three columns."
E_BED_NO_HDR <- "BED files must not contain a header."
E_CHROM_CHR <- "Chromosome names must start with 'chr'."
E_COL2_NUM <- "Column 2 must be numeric."
E_COL3_NUM <- "Column 3 must be numeric."
E_COL5_NUM <- "Column 5 must be numeric."
E_COL6_NUM <- "Column 6 must be numeric."
E_START_END <- "Chromosome start must not exceed chromosome end"
E_START_NUM <- "Start coordinate must be numeric."
E_END_NUM <- "End coordinate must be numeric."
E_POS_NUM <- "'pos' must be numeric."
E_P_NUM <- "'p' must be numeric."
E_VALID_BW <- "The file is not a valid bigWig file."
E_BAI_MISS <- "The BAM index (.bai) file is missing."
E_VALID_HIC <- "The file is not a valid HiC file."
E_HIC_NO_CHRINFO <- "The HiC file contains no chromosome information."
E_BEDPE_6COL <- "BEDPE files must contain at least six columns."
E_BEDPE_NO_ROWS <- "BEDPE file contains no valid data rows."
E_COL1_CHROM <- "Column 1 must contain chromosome names."
E_COL4_CHROM <- "Column 4 must contain chromosome names."
E_BEDPE_1_START_END <- "BEDPE first interval has start greater than end."
E_BEDPE_2_START_END <- "BEDPE second interval has start greater than end."
E_BEDPE_ORDER <- "BEDPE intervals are not ordered: first anchor should precede second anchor."
E_REG_MIN3COL <- "Region files must contain at least three columns."
E_REG_MAX6COL <- "Region files can contain at most six columns."


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
      all.errors <- c(all.errors,
                      paste0("\nFile: ", basename(file), "\n",
                             paste("  -", res$errors, collapse = "\n")))
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
    return(validationResult(c(errors, E_FOPEN)))

  # Check number of columns before accessing them
  if (ncol(bed) < 3) {
    errors <- c(errors, E_BED_MIN3COL)
    return(validationResult(errors))
  }

  if (tolower(as.character(bed[[1]][1])) %in%
      c("chr","chromosome", "chrom"))
    errors <- c(errors, E_BED_NO_HDR)

  if (!all(startsWith(as.character(bed[[1]]), "chr")))
    errors <- c(errors, E_CHROM_CHR)

  if (!is.numeric(bed[[2]]))
    errors <- c(errors, E_COL2_NUM)

  if (!is.numeric(bed[[3]]))
    errors <- c(errors, E_COL3_NUM)
  if (any(bed[[2]] > bed[[3]]))
    errors <- c(errors, E_START_END)

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
    return(validationResult(c(errors, E_FOPEN)))
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
    errors <- c(errors, E_CHROM_CHR)

  if (!is.numeric(bed$start))
    errors <- c(errors, E_START_NUM)

  if (!is.numeric(bed$end))
    errors <- c(errors, E_END_NUM)

  if (any(bed$start > bed$end))
    errors <- c(errors,E_START_END)

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
    return(validationResult(c(errors, E_FOPEN)))

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
      errors <- c(errors, E_CHROM_CHR)

  if ("pos" %in% names(gwas))
    if (!is.numeric(gwas$pos))
      errors <- c(errors, E_POS_NUM)

  if ("p" %in% names(gwas))
    if (!is.numeric(gwas$p))
      errors <- c(errors, E_P_NUM)
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
    ## We are a bit unhappy this does not work on Win$ systems (see import help)
    if( .Platform$OS.type != "windows" )
      rtracklayer::import(path)
    TRUE
  }, error = function(e) FALSE)

  if (!ok)
    errors <- c(errors, E_VALID_BW)
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
    errors <- c(errors, E_BAI_MISS)
  # check readability
  ok <- tryCatch({
    Rsamtools::BamFile(path)
    TRUE
  }, error = function(e) FALSE)

  if (!ok)
    errors <- c(errors, E_FOPEN)

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
    errors <- c(errors, E_VALID_HIC)
  } else if (nrow(chroms) == 0) {
    errors <- c(errors, E_HIC_NO_CHRINFO)
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
    return(validationResult(c(errors, E_FOPEN)))

  # Minimum columns
  if (ncol(bedpe) < 6) {
    errors <- c(errors, E_BEDPE_6COL)
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

    return(chrA & chrB & !any(is.na(coords)))
  }

  if (nrow(bedpe) >= 2) {
    first.valid <- checkHeader(bedpe[1, ])
    second.valid <- checkHeader(bedpe[2, ])
    # if first row fails but second works assume header
    if (!first.valid & second.valid) {
      bedpe <- bedpe[-1, ]
    }
  }
  # If after header removal no data remain
  if (nrow(bedpe) == 0)
    return(validationResult(c(errors, E_BEDPE_NO_ROWS)))

  # Check format of chrom after fixing optional header
  if (ncol(bedpe) >= 1 & !all(startsWith(as.character(bedpe[[1]]), "chr")))
    errors <- c(errors, E_COL1_CHROM)

  if (ncol(bedpe) >= 4 & !all(startsWith(as.character(bedpe[[4]]), "chr")))
    errors <- c(errors, E_COL3_CHROM)

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
    ## XXX all()??
    if (is.numeric(bedpe[[2]]) & is.numeric(bedpe[[3]]) &
        any(bedpe[[2]] > bedpe[[3]])) {
      errors <- c(errors, E_BEDPE_1_START_END)
    }

    if (is.numeric(bedpe[[5]]) & is.numeric(bedpe[[6]]) &
        any(bedpe[[5]] > bedpe[[6]])) {
      errors <- c(errors, E_BEDPE_2_START_END)
    }

    if (is.numeric(bedpe[[2]]) & is.numeric(bedpe[[5]]) &
        any(bedpe[[2]] > bedpe[[5]])) {
      errors <- c(errors, E_BEDPE_ORDER)
    }
  }
  validationResult(errors)
}

########### ------ REGION TABLE VALIDATOR FUNCTION

validateRegionFile <- function(path) {
  errors <- character()
  # check file extension
  err <- checkExtension(path,
                        c("bed", "txt", "tsv"))
  if (!is.null(err))
    errors <- c(errors, err)
  # check if file readable
  reg <- readPreview(path,
                     col_names = FALSE)

  if (is.null(reg))
    return(validationResult(c(errors, E_FOPEN)))

  if (ncol(reg) < 3) {
    errors <- c(errors, E_REG_MIN3COL)
    return(validationResult(errors))
  }

  if (ncol(reg) > 6)
    errors <- c(errors, E_REG_MAX6COL)

  if (ncol(reg) >= 1) {
    if (!all(startsWith(as.character(reg[[1]]), "chr")))
      errors <- c(errors, E_CHROM_CHR)
  }

  if (ncol(reg) >= 2) {
    if (!is.numeric(reg[[2]]))
      errors <- c(errors, E_COL2_NUM)
  }

  if (ncol(reg) >= 3) {
    if (!is.numeric(reg[[3]]))
      errors <- c(errors, E_COL3_NUM)
  }

  if (ncol(reg) >= 3 & is.numeric(reg[[2]]) & is.numeric(reg[[3]])) {
    if (any(reg[[2]] > reg[[3]]))
      errors <- c(errors, E_START_END)
  }
  validationResult(errors)
}

## Run different validation function if the file provided to bed.file is .bed
## or .bam
validateBedOrBam <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "bam") {
    return(validateBam(path))
  } else {
    return(validateBed(path))
  }
}
