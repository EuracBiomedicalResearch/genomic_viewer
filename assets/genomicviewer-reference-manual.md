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
2.  [File formats](#file-formats)
3.  [Features and Usage](#features-and-usage)
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

## File Formats

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

### Export Functionalities
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

## Tutorial

This section contains an easy tutorial explaining how to use ***Genomic Viewer*** through a practical example with real data.

In this tutorial you will learn how to:
- Correctly set navigation parameters to visualize genomic tracks.
- Navigate throughout the genome.
- Generate a plot with diverse genomic data.
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

### Biological question

When loading custom datasets in ***Genomic Viewer*** the choice can be driven by either **technical or biological** questions. The visualization of genomic tracks can indeed validate the quality of both sequencing raw data and some downstream analysis,
like [peak calling](https://www.sciencedirect.com/science/article/pii/S1046202320300591). In addition, it is also very useful for investigation biological questions.
Considering the data that are loaded as usage example in the present tutorial, an interesting biological question can be to *identify SNPs (from the GWAS data) found in CKD patients that are associated to relevant genes for kidney function*.

### Genome selection, navigation and plot inspection

Before starting to inspect the data tracks it is essential to select the correct reference genome. When ***Genomic Viewer*** is started it loads by default the human *reference genome hg19* (GRCh19).
The usage example data are mapped to the human *reference genome hg38* (GRCh38). Therefore the first thing to do to ensure correct annotation of the data is to choose the right version of the genome from the top left drop-down menu.

<img src="GV_ref_genome.png" alt="GV reference genome selection" width="20%">

To next navigate across the genome there are several options, described in detail in the *Navigation section* of [Features and Usage](#features-and-usage).

Since the example data used in this tutorial include the whole *chromosome 5* we can start taking an overview of the entire chromosome 5 by clicking on it form the **Choose chromosome** interactive plot
in the upper right sidebar.

<img src="GV_choose_chrom.png" alt="GV interactive chromosome hover plot" width="25%">

Upon click you will see that the coordinates are passed to the *Load coordinates* panel on the left sidebar. Make sure that the *Plot* navigation tab is selected form the main central window. 
Next click the *Go button* to generate the corresponding genomic screenshot plot.

<img src="GV_chr5_overview.png" alt="GV overview of chromosome 5 example genomic tracks" width="80%">

From a quick look at the generated plot, a cluster of significant SNPs close to the right chromosome end appear from the GWAS data. It is worthy to take a close look.
For this aim the user can employ the *drag and drop zoom bar* at the bottom of the plot. In this tutorial the coordinates of the region arounf the SNPs cluster were already saved as custom coordinates list
and uploaded as default through the configuration file. The user can access these coordinates form the from the *Load Coordinates* panel in the left sidebar. 
By clicking on the first entry in the list, the corresponding coordinates (relative to the gene SLC34A1) are passed to the tool and the *Insert Coordinates* panel will automatically update.

<img src="GV_region_table_example.png" alt="GV coordinates selection from custom list" width="25%">

As before, make sure that the *Plot* navigation tab is selected form the main central window. Next click the *Go button* to generate the corresponding genomic screenshot plot.

<img src="GV_navigation_tabs.png" alt="GV navigation tabs Plot selected" width="20%">

If you are not satisfied of the output you can adjust the selected genomic range by zooming-in and out through the zoom panel at the bottom of the *Plot tab* and
eventually save the new coordinates in the region table by clicking on the *Add button*.

<img src="GV_chr5_zoom.png" alt="GV zoom of chromosome 5 example genomic tracks" width="80%">

From the zoomed plot we can distinguish more clearly the significant SNPs, the gene in which they are found (SLC34A1) and some epigenetic features of this locus, like the presence of *regulatory elements*, *ATAC-seq peaks* and the proximity to a *3D chromatin loop* (HiC arch).

<img src="GV_save_window.png" alt="GV save button and popup window with export formats" width="60%">

### Download of the genomic view plot

Once you are satisfied of the generated genomic view plot you can choose to download it through the *Save button* in the bottom left sidebar. This will open a popup window through which you can choose the file format
among: .pdf, .svg, .png and .jpeg. See *Export Functionalities* in the [Features and Usage](#features-and-usage) section.

### Export raw data subsets

In addition to the plot of genomic tracks, ***Genomic Viewer*** offers the possibility to investigate the input data more deeply. One of the provided options to easily extract details about a user selected genomic range
is through the *Data tab* of the main central window.

<img src="GV_navigation_tabs_data.png" alt="GV navigation tabs Data selected" width="20%">

From here you can export a filtered version of the raw data of some of the tracks, limited to the region that you selected from the genome navigation options. 
In the working example the region is the one corresponding to SLC34A1 gene (chr5: 177365507-177412577) and this option is useful to:
- Extract the *rs IDs* and the *alternative DNA bases* in the two SNPs alleles, from the GWAS table.
- Evaluate the category of the *regulatory elements* that are found in the risk locus.
- Understand if there is overlap with *open chromatin ATAC-seq* peaks.

For example we can easily see that the 4 SNPs above the significance threshold have the following IDs: rs3812035, rs6420094, rs6862195, rs7447593. This can be useful to search the literature for reported information on their effect on CKD or other pathologies.

While form the visual inspection of the plot we can only gain qualitative readouts, the possibility to export the detailed information from the raw data allow the formulation of more robust interpretations.  

The subset tables can be inspected form the application interface preview or downloaded from the *Download button* below each table.

<img src="GV_gwas_table_example.png" alt="GV save button and popup window with export formats" width="60%">

### Evaluate data from stats

***Genomic Viewer*** also offers a handful of dataset-specific plots accessible from the *Stats tab*.

<img src="GV_navigation_tabs_stats.png" alt="GV navigation tabs Stats selected" width="20%">

Each of these plot can be generated by clicking the *Run* button in the corresponding section.
Since our example include all the data types associated to a Stats plot you can try to generate all of them. For a detailed description of the single plots you can refer to the *Analysis Tools* in the [Features and Usange](#features-and-usage) section.


Descrizione dei singoli output con immagine.
- 
-
-

### Biological interpretation

INtegrating the information from the genomic view plot with the details highlighted in the stats can be very helpful in the formulation of biologically relevant hypothesis, for example...
riportare esempio descritto nel paper.


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

### Literature

------------------------------------------------------------------------

