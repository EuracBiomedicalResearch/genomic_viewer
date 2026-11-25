### Function to add popover information to data tracks

## Notes:
# 1) In the popover_data$track.names variable the order of names reflects the order
#    of the tracks in the plot: BW, BED, CAT, BEDPE, GWAS.

add_popovers <- function(svg, popover_data) {
  
  ###--- Initial controls
  # Ensure SVG is a character string
  svg <- as.character(svg)
  if (is.null(svg) || length(svg) != 1 || is.na(svg)) {
    stop("Invalid SVG input.")
  }
  # Check popover metadata
  if (is.null(popover_data) || length(popover_data) == 0) {
    return(svg)
  }
  
  # popover_data <- popover_data %>%
  #   dplyr::arrange(start, end)
  
  ###--- Extracting SVG elements info and data
  # Parse SVG
  doc <- xml2::read_xml(charToRaw(svg))
  
  # Extract all SVG rectangles
  rects <- xml2::xml_find_all(
    doc,
    "//*[local-name()='rect']"
  )
  
  
  ###--- Find TRACKS rectangles
  # Extract rectangle information
  rect_info <- data.frame(
    index = seq_along(rects),
    x = as.numeric(xml2::xml_attr(rects, "x")),
    y = as.numeric(xml2::xml_attr(rects, "y")),
    width = as.numeric(xml2::xml_attr(rects, "width")),
    height = as.numeric(xml2::xml_attr(rects, "height")),
    style = xml2::xml_attr(rects, "style"),
    stringsAsFactors = FALSE
  )
  
  # Identify target rectangles
  track_rect_indices <- which(
    !is.na(rect_info$style) &
      grepl("stroke\\s*:\\s*none", rect_info$style) &
      !grepl("fill\\s*:", rect_info$style)
  )
 
  # Select just rect indices of rects aligned to tracks window
  track_rect_indices <- rect_info$index[
    track_rect_indices[which(
      rect_info$x[track_rect_indices] == rect_info$x[track_rect_indices[1]])
      ]]
  # Exclude first rect (page rect), positioning line and gene tracks (last rect)
  track_rect_indices <- track_rect_indices[c(-1,-2, -length(track_rect_indices))]
  
  # Keep selected rectangles
  track_rects <- rects[track_rect_indices]
  track_rect_info <- rect_info[track_rect_indices, ]
  
  
  ##### To be commented after DEBUG HAS ended
  # Debugging output
  # cat(
  #   "Number of selected track rectangles:",
  #   length(track_rects), "\n"
  # )
  
  #print(track_rect_info)
  ##### END To be commented after DEBUG HAS ended
  
  ###--- Find BED peaks rectangles
  # Find track rectangles indices of BED tracks
  bed_indices <- which(names(popover_data$track.names) == "bed")
  bed_rect_indices <- track_rect_info$index[bed_indices]
  bed_rect_info <- rect_info[bed_rect_indices, ]
  
  # Store BED peak rectangles and their information
  bed_peaks_rect_list <- list()
  bed_peaks_info_list <- list()
  
  for (i in seq_along(bed_indices)) {
    bed_peaks_info <- rect_info %>%
      dplyr::filter(
        y == bed_rect_info$y[i],
        height == bed_rect_info$height[i],
        index != bed_rect_info$index[i],
        !is.na(style)
      )
    
    # Sort rectangles by x
    sorted_bed <- sort_elements_by_x(
      element.info = bed_peaks_info,
      element = rects
    )
    
    bed_peaks_rect_list[[i]] <- sorted_bed$elements
    bed_peaks_info_list[[i]] <- sorted_bed$info
  }
  
  ###--- Find CAT BED peaks rectangles
  # Find track rectangles indices of BED tracks
  cat_indices <- which(names(popover_data$track.names) == "cat")
  cat_rect_indices <- track_rect_info$index[cat_indices]
  cat_rect_info <- rect_info[cat_rect_indices, ]
  
  # Store cat peak rectangles and their information
  cat_peaks_rect_list <- list()
  cat_peaks_info_list <- list()
  
  for (i in seq_along(cat_indices)) {
    cat_peaks_info <- rect_info %>%
      dplyr::filter(
        y == cat_rect_info$y[i],
        height == cat_rect_info$height[i],
        index != cat_rect_info$index[i],
        !is.na(style)
      )
    
    # Sort CAT peaks by x
    sorted_cat <- sort_elements_by_x(
      element.info = cat_peaks_info,
      element = rects
    )
    
    cat_peaks_rect_list[[i]] <- sorted_cat$elements
    cat_peaks_info_list[[i]] <- sorted_cat$info
  }
  
  ###--- Find BEDPE loops polygons
  # Extract all SVG polygons
  polygons <- xml2::xml_find_all(
    doc,
    "//*[local-name()='polygon']"
  )
  
  ###--- Find TRACKS polygons
  # Extract polygons information
  polygon_info <- data.frame(
    index = seq_along(polygons),
    points = xml2::xml_attr(polygons, "points"),
    style = xml2::xml_attr(polygons, "style"),
    stringsAsFactors = FALSE
  )
  
  # Add column with y coordinate
  polygon_info <- polygon_info %>%
    dplyr::mutate(
      x = vapply(points, function(p) {
        coords <- as.numeric(
          unlist(strsplit(trimws(p), "[,[:space:]]+"))
        )
        coords[1]
      }, numeric(1)),
      
      y = vapply(points, function(p) {
        coords <- as.numeric(
          unlist(strsplit(trimws(p), "[,[:space:]]+"))
        )
        coords[2]
      }, numeric(1))
    )
  
  # Find track rectangles indices of BEDPE tracks
  bedpe_indices <- which(names(popover_data$track.names) == "bedpe")
  bedpe_rect_indices <- track_rect_info$index[bedpe_indices]
  bedpe_rect_info <- rect_info[bedpe_rect_indices, ]
  
  # Store BEDPE peak polygons and their information
  bedpe_peaks_polygon_list <- list()
  bedpe_peaks_info_list <- list()
  
  for (i in seq_along(bedpe_indices)) {
    bedpe_peaks_info <- polygon_info %>%
      dplyr::filter(
        y == bedpe_rect_info$y[i],
        !is.na(style)
      )
    
    # Sort bedpe peaks by x
    sorted_bedpe <- sort_elements_by_x(
      element.info = bedpe_peaks_info,
      element = polygons
    )
    
    bedpe_peaks_polygon_list[[i]] <- sorted_bedpe$elements
    bedpe_peaks_info_list[[i]] <- sorted_bedpe$info
  }
  
  ###--- Find GWAS circles
  # Extract all SVG circles
  circles <- xml2::xml_find_all(
    doc,
    "//*[local-name()='circle']"
  )
  
  ###--- Find TRACKS circles
  # Extract circles information
  circle_info <- data.frame(
    index = seq_along(circles),
    x = as.numeric(xml2::xml_attr(circles, "cx")),
    y = as.numeric(xml2::xml_attr(circles, "cy")),
    r = as.numeric(xml2::xml_attr(circles, "r")),
    style = xml2::xml_attr(circles, "style")
  )
  
  # Find track rectangles indices of GWAS tracks
  gwas_indices <- which(names(popover_data$track.names) == "gwas")
  gwas_rect_indices <- track_rect_info$index[gwas_indices]
  gwas_rect_info <- rect_info[gwas_rect_indices, ]
  
  # Store gwas circles and their information
  gwas_circle_list <- list()
  gwas_circle_info_list <- list()
  
  for (i in seq_along(gwas_indices)) {
    gwas_info <- circle_info %>%
      dplyr::filter(
        y >= gwas_rect_info$y[i],
        y <= gwas_rect_info$y[i] + gwas_rect_info$height[i],
        !is.na(style)
      )
    
    # Sort gwas peaks by x
    sorted_gwas <- sort_elements_by_x(
      element.info = gwas_info,
      element = circles
    )
    
    gwas_circle_list[[i]] <- sorted_gwas$elements
    gwas_circle_info_list[[i]] <- sorted_gwas$info
  }
  

    # debug
  # cat("All circles info")
  # print(circle_info)
  # cat("gwas tracks rectangles\n ")
  # print(gwas_rect_info)
  # cat("Bed peaks circles\n ")
  # print(gwas_circle_info_list)
  #   # end debug
  
  
  ###--- Add tooltip
  ## Track rectangles
  tooltip_function(pop.element = track_rects,
                   pop.data = popover_data,
                   track.type = "names"
                   )
  ## Bed peaks
  for (i in seq_along(bed_peaks_rect_list)) {
    tooltip_function(
      pop.element = bed_peaks_rect_list[[i]],
      pop.data = popover_data$bed.tabs[[i]],#bed_peaks_info_list[[i]],
      track.type = "bed"
    )
  }
  ## Cat Bed peaks
  for (i in seq_along(cat_peaks_rect_list)) {
    tooltip_function(
      pop.element = cat_peaks_rect_list[[i]],
      pop.data = popover_data$cat.tabs[[i]],#bed_peaks_info_list[[i]],
      track.type = "cat"
    )
  }
  
  ## Bedpe loops 
  for (i in seq_along(bedpe_peaks_polygon_list)) {
    tooltip_function(
      pop.element = bedpe_peaks_polygon_list[[i]],
      pop.data = popover_data$bedpe.tabs[[i]],#bed_peaks_info_list[[i]],
      track.type = "bedpe"
    )
  }
  
  ## GWAS SNPs
  for (i in seq_along(gwas_circle_list)) {
    tooltip_function(
      pop.element = gwas_circle_list[[i]],
      pop.data = popover_data$gwas.tabs[[i]],#bed_peaks_info_list[[i]],
      track.type = "gwas"
    )
  }

  
  # Return modified SVG
  svg_out <- as.character(doc)
  
  return(svg_out)
}


## Helper function to sort SVG elements
sort_elements_by_x <- function(element.info, element) {
  # Determine sorting order
  ord <- order(element.info$x)
  # Sort rectangle information
  element.info <- element.info[ord, , drop = FALSE]
  # Reorder corresponding SVG elements
  sorted_element <- element[element.info$index]
  
  list(info = element.info,
      elements = sorted_element)
}


### Helper function to identify polygons boundaries
get_polygon_bounds <- function(polygon) {
  
  points <- xml2::xml_attr(polygon, "points")
  
  coords <- as.numeric(
    unlist(
      strsplit(
        trimws(points),
        "[,[:space:]]+"
      )
    )
  )
  
  if (length(coords) < 6 || length(coords) %% 2 != 0) {
    return(c(
      x = NA, x_max = NA,
      y_min = NA, y_max = NA
    ))
  }
  
  coords <- matrix(coords, ncol = 2, byrow = TRUE)
  
  c(
    x = min(coords[, 1]),
    x_max = max(coords[, 1]),
    y_min = min(coords[, 2]),
    y_max = max(coords[, 2])
  )
}


## Function to specify popover content
tooltip_function <- function(pop.element, pop.data, track.type){
  for (i in seq_along(pop.element)) {
    
    # Preserve existing fill behaviour, but make the
    # rectangle transparent and hoverable
    xml2::xml_set_attr(
      pop.element[[i]],
      "fill",
      "transparent"
    )
    
    xml2::xml_set_attr(
      pop.element[[i]],
      "pointer-events",
      "all"
    )
    
    # Apply red outline without changing other style properties !JUST FOR DEBUG!
    # style <- xml2::xml_attr(
    #   pop.element[[i]],
    #   "style"
    # )
    # 
    # style <- paste(
    #   style,
    #   "stroke: red !important;",
    #   "stroke-width: 3px !important;",
    #   "pointer-events: all;"
    # )
    # 
    # xml2::xml_set_attr(
    #   pop.element[[i]],
    #   "style",
    #   style
    # )
    
    ## STOP DEBUG SECTION
    
    # Add tooltip
    tooltip <- xml2::xml_add_child(
      pop.element[[i]],
      "title"
    )
    
    ## Define popover text based on track type
    if (track.type == "names"){
      pop.text <- paste0(
        "TRACK #", i,
        "\nTrack: ", pop.data$track.names[i])
    } else if (track.type == "bed"){
      pop.text <- paste0(
        "BED PEAK #", i,
        "\nPosition: ", pop.data$chr[i], ":", pop.data$start[i], "-", pop.data$end[i],
        "\nPeak length: ", pop.data$end[i]-pop.data$start[i], "bp")
    } else if (track.type == "cat"){
      pop.text <- paste0(
        "CAT PEAK #", i,
        "\nPosition: ", pop.data$chr[i], ":", pop.data$start[i], "-", pop.data$end[i],
        "\nPeak length: ", pop.data$end[i]-pop.data$start[i], "bp",
        "\nCategory: ", pop.data$category[i])
    } else if (track.type == "bedpe"){
      pop.text <- paste0(
        "BEDPE LOOP #", i,
        "\nAnchor A: ", pop.data$chrA[i], ":", pop.data$startA[i], "-", pop.data$endA[i],
        "\nAnchor B: ", pop.data$chrB[i], ":", pop.data$startB[i], "-", pop.data$endB[i],
        "\nLoop length: ", pop.data$endB[i]-pop.data$startA[i], "bp")
    } else if (track.type == "gwas"){
      pop.text <- paste0(
        "GWAS TRACK #", i,
        "\nPosition: ", pop.data$chrom[i], ":", pop.data$pos[i],
        "\nSNP ID: ", pop.data$snp[i],
        "\np-adj: ", pop.data$p[i])
    } 
    
    
    xml2::xml_text(tooltip) <- pop.text
  }
}
