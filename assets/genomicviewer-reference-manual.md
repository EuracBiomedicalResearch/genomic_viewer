---

# Genomic Viewer Reference Manual
<div align="center">
<img src="GV_scheme.png" width="60%"/>
</div>

**Version:** 1.0.0\
**Description:** Genomic Viewer is a cross-platform application for visualizing and analyzing genomic data hosted in a Docker container.

------------------------------------------------------------------------

## Table of Contents

<details open>
<summary>&nbsp;</summary>

1.  [Configuration](#configuration)
2.  [Features and Usage](#features-and-usage)
3.  [File formats](#file-formats)
4.  [Tutorial](#tutorial)
5.  [Getting Help](#help)
6.  [References and Links](#references-links)

</details>

------------------------------------------------------------------------

## Configuration

Document all configurable items:
- Application preferences
- Environment variables
- Integration with external tools

------------------------------------------------------------------------

## Features and usage

Explain major features in dedicated subsections.

### Data Import
How to load files, accepted formats, drag-and-drop support.

### Reference Genome
How to choose reference genome and which are the available options and the affeted sections in the viewer.

### Navigation

### Visualization
Plots, settings, export options.

### Analysis Tools
All computational or analytical modules.

### Export Functionality
Which file formats can be exported.

### Central Panels
- Plot viewer
- Data viewer
- Stats panel


### Sidebars Actions

</div>

**Left sidebar**

| Section/Button     | Function                                                                                                                                             |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| Reference genome   | Select a reference genome form list                                                                                                                  |
| Insert coordinates | Choose chromosome to visualize from drop-down menu and enter start and end coordinates                                                               |
| Load coordinates   | Load a bed format file with a list of saved genomic coordinates, if present, the file specified in the configuration file will be loaded as default  |
| Go button          | generate plot according to the selected options                                                                                                      |
| Save button        | Export plot choosing among different formats: .svg, .pdf, .png, .jpg  

------------------------------------------------------------------------

## File Formats

------------------------------------------------------------------------

## Tutorial

This section contains an easy tutorial explaining how to use ***Genomic Viewer*** through a practical example with real data.

In this tutorial you will learn how to:
- Correctly set navigation and graphical parameters to visualize genomic tracks.
- Generate a plot with diverse genomic data.
- Navigate throughout the genome.
- Export subset of the raw data.
- Evaluate data based on the stats.
- Formulate biological hypothesis driven by data integration.

### Loading usage example data

The genomic data to be loaded must be entered through the `GenomicViewer_config.yml` configuration file as described in the [Configuration section](#configruation).
In this tutorial we will exploit as usage example the data that are loaded by default in the pre-compiled *configuration file* that is saved upon ***Genomic Viewer*** installation.
These are publicly available data from the *Human Kidney cortex* and *Chronic Kidney Disease (CKD)*. 
*Note:* The dataset which is made available upon ***Genomic Viewer*** installation only includes *chromosome 5* as lightweight sample. For the user that wants full data accessibility please see [References and Links](#references-links)
and download data form source databases. Save the files in the `./data` folder and update the **configuration file** with the correct file paths and labels.

<img src="GV_configuration_example.png" alt="GV configuration file and data" width="80%">

### Genome selection and navigation

Before starting to inspect the data tracks it is essential to select the correct reference genome. When ***Genomic Viewer*** is started it loads by default the human *reference genome hg19* (GRCh19).
The usage example data are mapped to the human *reference genome hg38* (GRCh38). Therefore the first thing to do to ensure correct annotation of the data is to choose the right version of the genome from the top left drop-down menu.

<img src="GV_ref_genome.png" alt="GV reference genome selection" width="20%">

To next navigate across the genome there are several options, described in detail in the *Navigation section* of [Features and Usage](#features-and-usage). For this tutorial we will select one of the saved coordinates available
from the *Load Coordinates* panel in the left sidebar. By clicking on the first entry in the list, the corresponding coordinates (relative to the gene SLC34A1) are passed to the tool and the *Insert Coordinates* panel will automatically update.

<img src="GV_region_table_example.png" alt="GV coordinates selection from custom list" width="30%">

Make sure that the *Plot* navigation tab is selected form the main central window. Next click the *Go button* to generate the corresponding genomic screenshot plot.



------------------------------------------------------------------------

## Getting Help

For **general support** questions, **reporting a bug** or **suggest a new feature** you can create an issue in our [Github repository](https://github.com/EuracBiomedicalResearch/genomic_viewer).

For **confidential reports** you can contact us by [email](mailto:sara.lago@eurac.edu).

------------------------------------------------------------------------

## References and Links

### Data Availability

 The data employed in the *usage example tutorial* are publicly available from [GEO](https://www.ncbi.nlm.nih.gov/geo/) and [GWAS catalog](https://www.ebi.ac.uk/gwas/) under the accession numbers listed below:

- HiC (GEO GSE212910)
- ATAC-seq (GEO GSE212908)
- CKD GWAS (GWAS Catalog 26831199)

Regulatory elements were downloaded from [UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables). 

------------------------------------------------------------------------

