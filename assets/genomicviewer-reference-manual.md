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

<details open>
<summary>&nbsp;</summary>

Upon [***Genomic Viewer*** installation](https://github.com/EuracBiomedicalResearch/genomic_viewer/blob/docker-genomicviewer/README.md#installation) the user is asked to choose a local directory that the app will be able to access to load the working datasets. 
In that folder the installer will create by default a `/data` directory containing the *tutorial example data* and a *configuration file*.

The `GenomicViewer_config.yml` file is the only configurable object that is essential for starting a ***Genomic Viewer*** session. 
This file allows the user to specify the input datasets to upload and assign sample labels to be displayed in the graphics.
The usage of a configuration file to provide locally saved data to ***Genomic Viewer*** has the advantage to:

- Avoid graphically heavy interface to manually choose individual files from local directories;
- Keep all the files robustly organized in a common parent directory;
- Avoid to use hard-coded personal paths; 
- Make it easy to share working sessions with any user that has access to the raw data.

Here are some indications to correctly fill the configuration file:


- It is not necessary to change the `data.dir` field unless you created a common sub-directory to `/data` with all the files to be uploaded;

- The configuration file reports a single section relative to each accepted [File Format](#file-formats);

- Each section requires three fields: `dir` for the specific sub-directory, if present; `ext` for the file extension or shortest common substring in file names of the same type; 
and `names` which is an array of quoted string to be used as labels for the input data.

**Note:** 
In the `ext` fields you can use regular expressions [regular expressions](https://www.geeksforgeeks.org/dsa/write-regular-expressions/) as input, use only the file extension as parameter or type the entire file name for safety.
When loading several files of the same format through extension or regular expression please remember that file are alway read in alphabetical order, therefore their *name labels* must follow the file order to be correectly assigend.
In the presence of multiple subfolders with data of the same file format, the `dir` field also accepts an arraz following the same rules of `name` labels arrays.
When loading **.bam** files it is recommended to use the regular expression `$` to specify the end of the file extension (like this `.bam$`), this avoids to erroneously try to load the associated *.bai* files.

- You can have more versions of the configuration file, but only the file named `GenomicViewer_config.yml` will be read by the tool in the working session.
It is suggested to keep additional versions in a separated location on your computer to avoid confusion.

- When one filed is empty because you do not want to enter a subdirectory, assign a name or you just do not have a specific file format to load, you must enter a **two whitespaces** empty string "  " or vector '[""]' to prevent unwanted behaviors 

- The last field in the configuration file refers to a custom bed file with a saved preset of coordinateds of interest. This file con be substituted or dynamically modified during every working session.

- Most of these instructions and field description are also summarized in the configuration file itselt so you do not need to refer to the manual every time.

An example of the configuration file is reported below:

```{yaml}
---

default:

    # Set here the parameters related to the input files path and extensions
    
  # Data directory
  data.dir: "/data/"
  
  # bigWig directory and files final pattern or complete name (can correspond to one or more tracks), ordered file name to visualize. If empty type "  " or [""] in names.
  bw.dir: "GSE212908_RAW_ATAC_bigwig"
  bw.ext: "treat_pileup_chr5.bw"
  bw.names: ["Kidney cortex 12", "Kidney cortex 15"] # Comma separated, "quoted" names
  
  # bedpe directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  bedpe.dir: "GSE212910_RAW_HiC_bedpe"
  bedpe.ext: "GSM6560960_mustache_0.1_0.2_out.diffloops_in_cortex_2_chr5.bedpe"
  bedpe.names: ["HiC arches"] # Comma separated, "quoted" names
  
  # bed or bam directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  bed.dir: "GSE212908_ATAC_peaks"
  bed.ext: "GSE212908_RAM012_013_015_peak_masterlist_chr5.bed"
  bed.names: ["ATAC peaks"] # Comma separated, "quoted" names
  
  # hic directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  hic.dir: "GSE212910_RAW_HiC"
  hic.ext: "GSM7749626_Cortex_partitioned_donor5_DM_chr5_50000.ginteractions.tsv.short.sorted.hic"
  hic.names: ["HiC cortex"] # Comma separated, "quoted" names
  
  # GWAS directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  gwas.dir: "GWAScatalog_KidneyDisease"
  gwas.ext: "relocatedCol_chr5.tsv"
  gwas.names: ["GWAS CDK"]
  
  # categorical bed file. If empty type "  " or [""] in names. Columns must be names and the one with category must be 'category'.
  cat.dir: ""
  cat.file: "regulatory_elements_hg38_chr5.bed"
  cat.names: ["Regulatory Elements"] # Comma separated, "quoted" names
  
  # file with selected genomic regions to be imported (bed format: chr, start end, name. No header). If empty type "  " or [""] in names.
  reg.dir: ""
  reg.file: "Example_region_table.bed"

```

***Important!*** It is required to **not change the configuration file name** and to keep it saved in the **same folder as the other app scripts and files**. 
You can modify its name when you want to store a configuration which is not in use anymore, or move it to a different directory outside of the tool.

</details>

------------------------------------------------------------------------

## File Formats

The following section will describe the file formats that can be imported in **Genomic viewer**, mentioning if there are specific requirements and for which track plot they are useful.

<details open>
<summary>bigwig</summary>

### bigwig

Most of the 2D NGS datasets are normally stored in bigWig file formats, a bigWig file represents values along the genome, such as read coverage, signal intensity, or enrichment scores.
BigWigs are indexed binary files allowing the fast access of selected portions of the file corresponding to a browsed genomic region. 

The most common data types that can be loaded through a bigWig file are ChIP-seq, CUT&Tag, ATAC-seq, RNA-seq and any genome-wide quantitative signal dataset.

For more details about the feature and creation of these files you can browse the [bigWig track format](https://genome.ucsc.edu/goldenpath/help/bigWig.html) webpage on the *UCSC web portal*.

</details>

<details open>
<summary>bed</summary>

### bed

[Bed files](https://www.ensembl.org/info/website/upload/bed.html) are normally used to store genomic ranges annotations, which can be for instance ChIP-seq or ATAC-seq peaks. 
Bed files con contain a variable number of columns with essential and optional information. For the purposes of ***Genomic Viewer*** only three tab separated fields are strictly 
necessary: **chromosome name**, **start**, **end**. 
As in the example below:

```
chr1  213941196  213942363
chr1  213942363  213943530
chr1  213943530  213944697
```
Make sure that your file does not have a header with column names (like `chr`, `start`, `end`, or a comment `#`) to ensure proper reafing of the file.
Additional columns are allowed, those will be displayed in the *Data* navigation tab, but are ignored for plotting.

</details>

<details open>
<summary>Categorical bed</summary>

### Categorical bed

In addition to the standard .bed file, ***Genomic Viewer*** also accepts **categorical .bed files** which are structured as the **standard bed** but have an additional required column, 
assigning the corresponding genomic range to a user-defined ***category***. In addition, differently from standard bed files, *categorical bed columns* are named with a header, as in the example below. 
Categorical bed can be used for example to classify peaks or functional genomic elements. For instance, several **functional elements** coordinates (like the ones provided for in the [tutorial](#tutorial)) can be downloaded from 
[**UCSC Table Browser**](https://genome.ucsc.edu/cgi-bin/hgTables).
The resulting file should look like this:

```
chr	start	end	category
chr1	155188536	155192004	h38_CpGIslands
chr1	2226773	2229734	h38_CpGIslands
chr1	36306229	36307408	h38_CpGIslands
chr1	47708822	47710847	h38_CpGIslands
chr1	53737729	53739637	h38_CpGIslands
chr1	101302963	101302972	h38_TSSpeaks
chr1	101304214	101304218	h38_TSSpeaks
```

Note that a same genomic range can belong to two different categories, in this case the entry must be repeated two times, with a single value in the category field. 
Additional columns will be ignored for plotting but are kept in the *Data* navigation tab.

*Categorical bed* format is highly flexible, allowing many different types of data to be organized according to this structure and can be adapted to a wide range of use cases.

</details>

<details open>
<summary>HiC</summary>

### HiC

3D contacts files, like HiC, stored in [hic file format](https://genome.ucsc.edu/goldenpath/help/hic.html). 
These is a binary format allowing for fast access to contact matrix heatmaps and is used for displaying chromatin conformation data in a browser.
*.hic* files are generally large file and can store the information at different resolutions and normalizations. It is suggested to include a column with *KR normalization*. 
To know more about .hic *normalization methods* you can refer to the [*Normalization of Hi-C Maps*](https://gcmapexplorer.readthedocs.io/en/latest/cmapNormalization.html) article.
Based on their availability in the source data file, ***Genomic Viewer*** reads **.hic** files at different resolutions depending on the size of the requested genomic window to plot. T
his ensures a faster access to the data and more lightweight outputs.

</details>

<details open>
<summary>bedpe</summary>

### bedpe

3D contacts can be represented not only as a heatmap or matrix, but also as arches connecting two distal genomic regions. 
This type of information is stored in the [.bedpe file format](https://bedtools.readthedocs.io/en/latest/content/general-usage.html#bedpe-format). 
Normally **bedpe files** are 6 columns files with *chr*, *start*, *end* fields of the two anchor and bait regions, however optional columns can be added. 
In the latter case 7th column must contain the name or id of the row in string format, the 8th column is a number representing the score and the 9th column represents the strand. 
Mis-formatting of these columns will result in an error. Column header is optional and will not affect the output.

An example of the minimal *.bedpe* file structure is reported below:

```
chrA  startA  endA  chrB  startB  endB
chr5	74050000	74060000	chr5	74640000	74650000
chr5	75350000	75360000	chr5	75670000	75680000
chr5	75740000	75750000	chr5	76150000	76160000
chr5	77560000	77570000	chr5	77960000	77970000
```
</details>

<details open>
<summary>GWAS</summary>

### GWAS

**Genome Wide Association Studies (GWAS)** datasets are stored in a format containing all the information that can be plotted as Manhattan plots.
The [**GWAS Catalog**](https://www.ebi.ac.uk/gwas/) official database storing this type of data has recently updated and uniformed the structure of the deposited **summary statistics** file format. 
These are normally stored as gzipped .tsv files since contain huge amount of data. 
To generate a **Manhattan plot** through  **Genomic viewer** there are four required fields, which contain information about **chromosome name**, **position**, **p-value** and **SNP id**. 
These fields must be tab separated and named with a header as in the example below:

```
chrom   pos         p       snp 
chr1	162766673	3.1e-01	rs1000050		
chr1	157285606	1.1e-02	rs1000073	
chr1	94701276	4.5e-01	rs1000075		
chr1	66392232	3.3e-01	rs1000085	
chr1	62967045	5.3e-01	rs1000127	
chr1	205536349	6.0e-01	rs1000312		
```

Any number of additional tab separated fields can be optionally added with no restriction in their name. 
All of the minimal required fields are always available in [**GWAS Catalog**](https://www.ebi.ac.uk/gwas/) summary statistics stored files. 
It is however recommended to check the columns headers to match the ***Genomic Viewer*** requirements. 
To reduce the filesize, the user which is only interested in plotting and not to exploit the *Data* subset funciton, can remove from the input dataframe the non-essential columns.

</details>

<details open>
<summary>bam</summary>

### bam

The **.bam** file format is used to store in a compressed binary version the results of sequencing reads alignments. To allow graphical tools to access this type of data the file must be indexed, therefor every **.bam** file 
must always be assocaited to a corresponding **.bam.bai** file. For a more extensive description of **bam ** files you can refer to the [BAM Track Format](https://genome.ucsc.edu/goldenpath/help/bam.html) of the UCSC web portal.
Sometimes publicly deposited **.bam** files are not indexed, in order to index a bam file it is recommended to use [*Samtools index*](https://www.htslib.org/doc/samtools-index.html) function.
**Bam** files are generally large files since they store information about single aligned reads.

</details>

------------------------------------------------------------------------

## Features and usage

In the following section the user will find a detailed description of the main functions that are available from ***Genomic Viewer*** interface.

<details open>
<summary>Interface organization</summary>

### Interface organization

***Genomic Viewer*** is organized into three main sections. A list with a brief description of the functions that are available from each section is schematized below.
It follows a more detailed description of usage of all the  mentioned functions.

<img src="GV_main_window_sections.png" alt="GV overview of the interface with sections" width="80%">

**Left sidebar**

| Section/Button     | Function                                                                                                                                             |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| Reference genome   | Select a reference genome form list.                                                                                                                 |
| Insert coordinates | Choose chromosome to visualize from drop-down menu and enter start and end coordinates.                                                              |
| Load coordinates   | Load a bed format file with a list of saved genomic coordinates. If present, the file specified in the configuration file will be loaded as default  |
| Go button          | Generate plot according to the selected options.                                                                                                     |
| Save button        | Export plot choosing among different formats: .svg, .pdf, .png, .jpg                                                                                 |


**Right sidebar**

| Section/Button     | Function                                                                                                                                             |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| Choose chromosome  | Select a chromosome to plot by hovering over the plot and clicking.                                                                                  |
| Search by gene     | Plot a genomic region by inserting the corresponding gene name.                                                                                      |
| bigWig plot mode   | Choose if plotting bigWig tracks in the profile or heatmap mode. Both plots can also be generated simultaneously.                                    |
| Autoscale settings | Define grouping rule for autoscaling bigWig tracks.                                                                                                  |
| Expand category    | Gives the possibility to expand tracks of categorical bed files to avoid categories overlap.                                                         |
| Expand transcripts | Alternative to gene label track, plots individually the available transcript isoforms.                                                               |
| Chromosome ideogram| Checked by default, allows to remove the chromosome ideogram form plot.                                                                              |

**Central window**

| Section/Button     | Function                                                                                                                                             |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| Plot, Data, Stats  | Click to access the corresponding navigation tab and the relative functions.                                                                         |
| Zoom section       | Zooming options available from the Plot tab. Provide functions for static zoom of the image or for dynamic genome navigation around a plotted region.|  

</details>

<details open>
<summary>Reference genome</summary>

### Reference genome

Choosing a *reference genome* is the first essential step to address before generating any plot. 
The reference genome provides the *correct coordinates* to ensure that the values you are entering in the navigation options correspond to the displayed *gene label and features*.
It can be selected from a built-in list available form a drop-down menu at the top of the **left sidebar**.  
The reference genome of choice must match the one used in the alignment of the track that are uploaded by the user through the [**Configuration file**](#configuration).
At ***Genomic Viewer*** startup the human hg19 (GRCh19) version of the reference genome is loaded as default.

<img src="GV_ref_genome.png" alt="GV select reference genome menu" width="25%">

Changing the selected working reference genome will affect also the list of chromosomes in the *Insert coordinates* panel, the **chromosome hover plot**, the list of available *gene names* and the gene annotation labels in the main plot output.

</details>

<details open>
<summary>Navigation</summary>

### Navigation

***Genomic Viewer*** offers several options to navigate across the genome. Their usage is described in the following section.

#### Insert coordinates

One option to tell ***Genomic Viewer*** which coordinates you want to plot is through the *Insert coordinates* panel. 
This panel allows to manually insert specific coordinates to be plotted by selecting the **chromosome name** from a drop-down menu, and entering the **start** and **end** coordinates in the numeric entry fields available fro the same panel.
Once you are satisfied of the entered coordinates, press the *Go button* to activate the generation of the plot or other analysis.

<img src="GV_insert_coordinates.png" alt="GV insert coordinates panel for genome navigation" width="25%">

#### Load coordinates

The user can navigate across a list of previously saved coordinates by specifying a *region table bed file* to be uploaded through the [configruation file](#configuration) or by accessing local files from a running ***Genomic Viewer*** session.
The provided coordinates list file should ideally be structured as a bed file with a minimum of three tab separated columns corresponding to: **chr**, **start**, **end**. It is suggested but not mandatory to have a fourth clumn with a name or ID for the corresponding genomic region.
It is also suggested to avoid column headers.

An example of region table bed file is reported below:

```
chr5	177365507	177412577	SLC34A1
chr5	177372928	177499184	SLC34A1_zoomOut
```
Once the region file is uploaded, the coordinates it contains become available to be selected form the **Select from menu** drop-down list.

<img src="GV_load_coordinates_menu.png" alt="GV load coordinates allows to choose coordinates from a saved list" width="25%">

A custom region table list can be dynamically created by the user by either generating a new one in the vase where no list is uploaded, or by modifying a previously uploaded table.
The **Add** and **Remove** buttons below the selection drop-down meno allow to access these options. In particular, to *Add* a new entry to the an existing list or to create a new one after clicking the *Add button*
a pop-up window will appear reporting the selected coordinates and allowing the user to assign a name to the region. By clicking *Ok* the entry and assigned name will be added to the list.

<img src="GV_load_coordinates_add.png" alt="GV load coordinates panel for adding new coordinates to list" width="25%">

Similarly, if you want to remove a coordinate from the uploaded list or you erroneously added an entry, you can select the entry form the drop-down list and next click the *Remove button*.
The new custom coordinates list can be also exported for storing it, having it available for a different session or sharing it with another user.

To restore the initial setting of the *Load coordinates* panel it is sufficient to click the *Reset button* at the panel's bottom.

#### Choose chromosome

To visualize the genomic screen of a whole chromosome or the corresponding analysis at the top of the **Right sidebar** the user can see a plot schematizing the *chromosomes structures* corresponding to the selected *reference genome*.
The plot will update every time that the user selects a different reference genome.
The *Choose chromosome plot* is an interactive plot that the user can hover with the mouse. A label with the **chromosome id** of the region that the user is hovering will apper below the graph. Upon click the corresponding coordinates are passed to ***Genomic Viewer***
and the genomic plo or desired analysis can be generated by pressing the *Go button*.

<img src="GV_choose_chrom.png" alt="GV choose chromosome hover and click plot" width="25%">

#### Search by gene

If a user is interested in visualizing or analyzing the genomic region corresponding to a specific gene, the easiest way is to retrieve its coordinates from the *Search by gene* menu.
This menu is updated accordingly to the selected *reference genome*. To search for a gene of interest you can start typing the gene name in the menu and a list with the matching entries will be displayed below.
Once your gene of interest appears you can click on it and the tool will automatically load its coordinates.
Note that if changing the reference genome after selecting for a gene the coordinates will not update automatically, but you have to search againg for the gene in the menu. This is for safety reasons since not all reference genomes encodes for the same genes, or have different nomenclatures.

<img src="GV_search_gene.png" alt="GV search by gene function" width="25%">

To trigger the generation of the plot or relative analysis, after choosing the gene of interest you must click the *Go button*

#### Zoom

The *zoom-panel* located at the bottom of the *Plot navigation panel* in the **Central Window** offers an alternative way for genome navigation. This is especially useful when a user wants to investigate the flanking regions of a selected genomic position
or on the opposite when starting from a wide genomic window there is the need to focus on a more restricted area as in the example reported in the [Tutorial](#tutorial).

There are two ways for using the *zoom-panel* for navigation:

- **Drag an drop bar**: below the static zoom button there is a draggable bar consisting in an orange rectangle, that matches the plotted genomic range, and grey flanking representing the ***25% extensions*** of the visualized range. The numbers below the bar report the coordinates in bp. 
By mouse drag-and-drop in the orange rectangle the user can zoom-in in the visualized genomic area, while by mouse drag-and-drop in the grey area the user can either zoom-out enlarging the actual genomic range or zoom-in in the flanking range. 
The maximum allowed zoom-in is **500 bp**, further zoom will not be allowed. Zooming by drag-and-drop is **limited to the selected chromosome coordinates**. 
The coordinates of the zoomed region will be automatically updated. You can repeat the action multiple times to update the coordinates and generate the plot only when you are satisfied by clicking the *Go button*.

- **Proportional zoom buttons**: the lowermost zoom option in the **Zoom bar** allows the user to **proportionally enlarge or restrict** the visualized genomic range, by keeping the initial region in the middle of the plotted area. 
Different buttons are available to zoom-in or out by **2x**, **5x** or **10x**. The user can click once or several times on each button, at every click the coordinates displayed in the **left sidebar** will update. 
To trigger the generation of the plot or analysis, click on the *Go button* once you are satisfied.

The maximum allowed zoom-in is **500 bp**, further zoom will not be allowed. Zooming by drag-and-drop is **limited to the selected chromosome coordinates**.

<img src="GV_zoom_bar.png" alt="GV navigation through zoom bar" width="25%">

</details>

### Visualization

- Track specific features
Plots, settings, export options.
In this section the user will find a description of the graphical output specific to the single data tracks and how they are managed by the tool. Since the basic graphical parameters are managed through the [`plotgardener`](https://phanstiellab.github.io/plotgardener/index.html)[[1]](#ref1)
R package, the specific function that handles each type of track is specified.

Bed files will be plotted by genomic viewer using the `plotgardener` function [`plotRanges()`](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html).
The same function is also employed to plot **.bam** files, the two formats are automatically detected by ***Genomic Viewer*** and while bed files are plotted in collpsed way, the bam are expanded to allow the visualization of individual reads.
- Zoom

### Genome annotation options
- expand transcripts
- chromosome ideogram

### Analysis Tools
Data subsetting
Stats plot description

### Run and Export Functionalities
- Go button
- Save button
- Data download buttons from Data navigation tab

### Central Panels
- Plot viewer
- Data viewer
- Stats panel


### Sidebars Actions



</details>

------------------------------------------------------------------------

## Tutorial

<details open>
<summary>&nbsp;</summary>

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
like **peak calling**[[2]](#ref2). In addition, it is also very useful for investigation biological questions.
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

<img src="GV_navigation_tabs.png" alt="GV navigation tabs Plot selected" width="20%">

<img src="GV_chr5_overview.png" alt="GV overview of chromosome 5 example genomic tracks" width="80%">

From a quick look at the generated plot, a cluster of significant SNPs close to the right chromosome end appear from the GWAS data. It is worthy to take a close look.
For this aim the user can employ the *drag and drop zoom bar* at the bottom of the plot. In this tutorial the coordinates of the region arounf the SNPs cluster were already saved as custom coordinates list
and uploaded as default through the configuration file. The user can access these coordinates form the from the *Load Coordinates* panel in the left sidebar. 
By clicking on the first entry in the list, the corresponding coordinates (relative to the gene SLC34A1) are passed to the tool and the *Insert Coordinates* panel will automatically update.

<img src="GV_region_table_example.png" alt="GV coordinates selection from custom list" width="25%">

As before, make sure that the *Plot* navigation tab is selected form the main central window. Next click the *Go button* to generate the corresponding genomic screenshot plot.
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

For the purpose of this tutorial we will only describe the outputs that provides more relevant insights for the proposed biological question:

- We have a *Manhattan plot* that summarizes in a single view what we already observed from the two genomic screen that were evaluated. There is a putative risk locus with a *cluster of significant SNPs* assocaited with CKD in the right telomere proximal region
of chromosome 5. A zoom-in of this region is useful to visually report the *rs IDs* of the significant SNPs as an alternative to the table generated in the *Data tab*.

- From the zoomed genomic screen comprising the risk locus we noticed the presence of several *regulatory elements*. The *categorical classification* chart is useful to evaluate their enrichment compare to their abundace in the whole genome.
For instance, the locus of interest is rich is *TSS peaks* resembling gene promoters, which makes this region very interesting since SNPs can have crucial effects on transcription regulation when occurring in regulatory regions like
promoters or enhancers.

- The *peak counts and overlap* plots report the presence of both open chromatin regions (ATAC-seq) and 3D chromatin interactions (HiC arches), strengthening the epigenetic importance of the investigated locus in kidney cells.

<img src="GV_stats_example.png" alt="GV example of stats plot relative to kidney data" width="80%">


### Biological interpretation

***Genomic Viewer*** combines interactive visual inspection of genomic data with essential analytical features.By enabling comparison across datasets and conditions, the tool helps identify patterns, 
trends, and regions of interest. In turn it allows to both answer to simple biological questions and guide the formulation of new hypotheses.

In the current example we were exploiting public data from the human kidney cortex and from patients with CKD to identify single nucleotide variants that can impact on the correct gene expression and functionality 
in the context of renal health. Through a simple overview of the *chromosome 5* it was possible to identify a cluster of SNPs signifcantly correlating to CKD.
By a closer investigation of this region it becomes evident that at least 6 of the most significant SNPs fall inside *SLC34A1 gene*. This gene encodes for a renal‐specific sodium–phosphate 
cotransporter responsible for the readsorption of filtered sodium and phosphate and expressed in the proximal tubule within the renal cortex (Fearn et al. 2018)[[3]](#ref3).
The clinical relevance of this gene product is supported by recent literature observing its downregulation in coditions of acute kidney injury (AKI)(Wilflingseder et al.)[[4]](#ref4).
For a user that would like to further investigate a molecular mechanism linking SNPs to SLC34A1 deregulation, the example data loaded into ***Genomic Viewer*** suggest that in healty condition SLC34A1 is in a context of open chromatin, and is in gene rich region with multiple regulatory elements.
Especially there is an overlap between the SNPs and an enhaner element, but also with several promoters. In turn HiC data revel the presence of a chromatin loop that connects the region upstream to SLC34A1 promtoer with 
distal elements. Altogether, these information can suggest that the presence of SNPs in the SLC34A1 locus can alter the function of epigenetic regulatory elements and the expression of the gene.
These hypothesis can be experimentally tested or adressed by integration of further genomic tracks, like RNA-seq or ChIP-seq.
This is a simple example of how the integrative visualization of genomic tracks can guide biological research to investigate otherwise unforeseen features. 

</details>

------------------------------------------------------------------------

## Getting Help
<details open>
<summary>&nbsp;</summary>

For **general support** questions, **reporting a bug** or **suggest a new feature** you can create an issue in our [Github repository](https://github.com/EuracBiomedicalResearch/genomic_viewer).

For **confidential reports** you can contact us by [email](mailto:sara.lago@eurac.edu).

</details>

------------------------------------------------------------------------

## References and Links
<details open>
<summary>&nbsp;</summary>

### Data Availability

 The data employed in the *usage example tutorial* are publicly available from [GEO](https://www.ncbi.nlm.nih.gov/geo/) and [GWAS catalog](https://www.ebi.ac.uk/gwas/) under the accession numbers listed below:

- HiC (GEO GSE212910)
- ATAC-seq (GEO GSE212908)
- CKD GWAS (GWAS Catalog 26831199)

Regulatory elements were downloaded from [UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables). 

### Literature
*1.*<a id="ref1"></a> Kramer NE, Davis ES, Wenger CD et al. Plotgardener: cultivating precise multi-panel figures in R. Bioinformatics 2022;38:2042–5.

*2.*<a id="ref2"></a> Nakato R, Sakata T. Methods for ChIP-seq analysis: A practical workflow and advanced applications. Methods 2021;187:44–53.

*3.*<a id="ref3"></a> Fearn A, Allison B, Rice SJ et al. Clinical, biochemical, and pathophysiological analysis of SLC34A1 mutations. Physiol Rep 2018;6:e13715.

*4.*<a id="ref4"></a> Wilflingseder J, Willi M, Lee HK et al. Enhancer and super-enhancer dynamics in repair after ischemic acute kidney injury. Nat Commun 2020;11:3383.

</details>

------------------------------------------------------------------------

