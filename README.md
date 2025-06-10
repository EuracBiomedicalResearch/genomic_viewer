<div style="width: 100vw;font-size:10px;text-align:center;">
  <span class="title"></span>
</div>
```html
<div style="width: 100vw;font-size:10px;text-align:center;">
  <span class="pageNumber"></span> <span / ></span> <span class="totalPages"></span>
</div>
```

```table-of-contents
title: ### Table of contents
```

## Overview
This **genomic viewer** app has been developed to allow the visualization of multi-omics data of several kind. It has been implemented in **[R](https://www.r-project.org/)** using **[Shiny](https://shiny.posit.co/)** and [Plotgardener for flexible genomic screen generation](https://phanstiellab.github.io/plotgardener/index.html) packages.  The application allows to generate and export genomic view plots as well as download tables with datasets on selected genomic regions and perform some basic statistics and additional plots providing an overview of the input data. 

## Input data
The following section will describe which types of input datasets accepts the **Genomic viewer** app, how to prepare and provide them.
### Reference genome 
At the moment the **Genomic viewer** app is set up just for the **[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)**  version of the human genome. However it can potentially be adapted to any other reference genome for which [Txdb annotation](https://bioconductor.org/packages/3.21/data/annotation/) R package is available.

#### Required files for genome annotation
The **[Plotgardener](https://phanstiellab.github.io/plotgardener/index.html)** function that is employed to generate the genomic view plot uses [Txdb annotation](https://bioconductor.org/packages/3.21/data/annotation/) package to plot the genomic features like the **Genomic label**, **Gene track** and names, **Expanded transcripts** isoforms and the **Chromosome ideogram**.

However, **additional files** must be also provided depending on the intended reference genome: 

##### Chromosome lengths and centromeres position

A .txt or .tsv file that contains the information about **chromosome name**, **centromere start**, **centromere end**, **chromosome length** and **order** to which chromosomes must be displayed.

The original file with such information can be retrieved from UCSC portal. For example the file for  **[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)** can be downloaded here:   https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/. This file contains several bins for centromeres that can be merged to obtain the file table using the script *[hg38_centromeres.rmd](<C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/hg38_centromeres.rmd>)*

This file is used in the app to store chromosomes coordinates which are needed to: 
i) **limit the zoom area** based on the selected chromosome length ([Zoom-in and out](#Zoom-in-and-out));
ii) plotting whole chromosome regions selected by the user from the **Choose chromosome** right panel ([Chromosome hover](#Chromosome-hover)).

```
chr	cen.start	cen.end	chr.len	order
chr1	122026459	124932724	248956422	1
chr2	92188145	94090557	242193529	2
chr3	90772458	93655574	198295559	3
chr4	49712061	51743951	190214555	4
chr5	46485900	50059807	181538259	5
chr6	58553888	59829934	170805979	6
chr7	58169653	61528020	159345973	7
chr8	44033744	45877265	145138636	8
chr9	43389635	45518558	138394717	9
chr10	39686682	41593521	133797422	10
chr11	51078348	54425074	135086622	11
chr12	34769407	37185252	133275309	12
chr13	16000000	18051248	114364328	13
```

##### HGNC genes symbol and coordinates

A .bed file that contains the information about chromosome, start, end, strand and the HGNC symbol or any other gene nomenclature desired by the user to be visualized for the gene search option. This file is used instead for allowing the **[Search by gene](#Search-by-gene)** option available in the **Choose chromosome** right panel.
The file should match the **reference genome version** on which all the tracks are annotated, it can be obtained through several sources, one option is to download the information from [**UCSC Table Browser**](https://genome.ucsc.edu/cgi-bin/hgTables), or in alternative a script is provided to directly retrieve the information from **[biomart](https://bioconductor.org/packages/release/bioc/manuals/biomaRt/man/biomaRt.pdf)**, arrange the data in the correct format and output the file. The script *[get_hgnc_symbol_hg38.rmd](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/get_hgnc_symbol_hg38.rmd>)* set for **[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)** is already provided together with the corresponding *[hg38_hgnc_symbol_cleaned.bed](<C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/hg38_hgnc_symbol_cleaned.bed>)* file. 
Here is a preview of how the file structure should be:

```
chromosome_name	start_position	end_position	strand	hgnc_symbol
19	58345178	58353492	-1	A1BG
15	28506625	28508808	-1	ABCB10P4
16	32726615	32729537	-1	ABHD17AP7
16	33140850	33143797	1	ABHD17AP9
10	26746593	26861087	-1	ABI1
8	18088569	18089687	-1	ABRAXAS1P2
17	63507056	63519806	1	ACE3P
20	45841721	45857405	-1	ACOT8
10	88932390	88940820	1	ACTA2-AS1
3	180820544	180821612	1	ACTBP16
1	77773865	77774864	-1	ACTG1P21
```

### Tracks data
The following section will describe the type of datasets that **Genomic viewer** accepts and the type of tracks that it can use for plotting.
#### HiC and 3D contact matrices
3D contacts files, like HiC, stored in [hic file format](https://genome.ucsc.edu/goldenpath/help/hic.html). These is a binary format allowing for fast access to contact matrix heatmaps and is used for displaying chromatin conformation data in a browser.
#### 3D contacts arches bedpe
3D contacts can be represented not only as a heatmap or matrix, but as well as arches that join two distal genomic regions that are found in contact. This type of information is stored in the [.bedpe file format](https://bedtools.readthedocs.io/en/latest/content/general-usage.html#bedpe-format). Normally **bedpe files** are 6 columns files with *chr*, *start*, *end* fields of the two anchor and bait regions, however optional columns can be added. In the latter case 7th column must contain the name of the row in string format, the 8th column is a number representing the score and the 9th column represents the strand. Mis-formatting of these columns will give an error. 
#### ChIP-seq, ATAC-seq, RNA-seq or any other bigWig 
Most of the 2D NGS datasets are normally stored in bigWig file formats, that are indexed binary files allowing the fast access of selected portions of the file corresponding to a browsed genomic region. The most common data types that can be loaded through a [bigWig file](https://genome.ucsc.edu/goldenpath/help/bigWig.html) are ChIP-seq, CUT&Tag, ATAC-seq, RNA-seq datasets.
#### Peaks bed 
[Bed files](https://www.ensembl.org/info/website/upload/bed.html) are normally used to store genomic ranges annotations, which can be for instance ChIP-seq or ATAC-seq peaks. Bed files con contain a variable number of columns with essential and optional information. For the purposes of this **Genomic viewer** only three tab separated fields are strictly necessary: **chromosome name**, **start**, **end**. As in the example below:

```
chr1  213941196  213942363
chr1  213942363  213943530
chr1  213943530  213944697
```
#### Categorical bed 
In addition to the standard .bed file, **Genomic viewer** also accepts categorical .bed which are structured as the [Peaks bed](#Peaks-bed) but have an additional required column assigning the corresponding genomic range to a ***category***. In addition, differently from   [Peaks bed](#Peaks-bed), categorical bed columns are named, as in the example below. Categorical bed can be used for example to classify peaks or functional genomic elements. For instance, several **functional elements** coordinates can be downloaded from [**UCSC Table Browser**](https://genome.ucsc.edu/cgi-bin/hgTables) and arranged in a single categorical bed file through the script [*generate_categorical_bed.Rmd](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/generate_categorical_bed.Rmd>)*. The resulting file (*[regulatory_elements_hg38.bed](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/regulatory_elements_hg38.bed>))* looks like this:

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
#### GWAS summary statistics
**Genome Wide Association Studies** datasets can be plotted as Manhattan plots starting from GWAS statistics files. The [**GWAS Catalog**](https://www.ebi.ac.uk/gwas/) official database for store this type of data has recently updated and uniformed the structure of the deposited **summary statistics** file format. These are normally stored as gzipped .tsv files since contain huge amount of data. 
To generate a **Manhattan plot** through  **Genomic viewer** there are four required fields, which contain information about **chromosome name**, **position**, **p-value** and **SNP id**. These fields must be tab separated and names as in the example below:

```
chrom   pos         p       snp 
chr1	162766673	3.1e-01	rs1000050		
chr1	157285606	1.1e-02	rs1000073	
chr1	94701276	4.5e-01	rs1000075		
chr1	66392232	3.3e-01	rs1000085	
chr1	62967045	5.3e-01	rs1000127	
chr1	205536349	6.0e-01	rs1000312		
```

Any number of additional tab separated fields can be optionally added with no restriction in their name. By starting from the [**GWAS Catalog**](https://www.ebi.ac.uk/gwas/) summary statistics format, a file which is organized as required by **Genomic viewer** can be arranged using the script *[GWAS_data_organization_for_plotgardener.Rmd](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/GWAS_data_organization_for_plotgardener.Rmd>)*. Based on the user choice, this script allows to rearrange the GWAS summary statistics and export a properly organized file either in:
i) a **short version** with just the minimal required columns;
ii) an **extended version** with the minimal required columns correctly names, plus all the other original fields.
### How to provide input datasets

The following section will describe how to provide the desired input datasets for being plotted in the **Genomic viewer**.
#### Configuration file

To allow users to provide locally saved dataset to the **genomic viewer** without an heavy graphical interface, an **[R configuration files (YAML)](#Configuration-file)** has been set up. The configuration file (*[Shiny_wzoom_config_hover.yml](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/Shiny_wzoom_config_hover.yml>)*) is structured as shown below and allows the user to load any number of datasets for all the accepted data types. Note that the ***ext field*** takes regular expressions as input and that when some of the specified entries is absent the corresponding field must be filled with a **two whitespace** empty string "  " or vector '[""]' as specified in the file comments.

```yml
---

default:

    # Set here the parameters related to the input files path and extensions
  # Data directory (uppermost common data directory)
  data.dir: "local/path/to/files/folder/"
  # bigWig directory and files final pattern or complete name (can correspond to one or more tracks), ordered file name to visualize. If empty type " " or [""] in names.
  bw.dir: "GSE212908_RAW_ATAC_bigwig"
  bw.ext: "treat_pileup.bw"
  bw.names: ["Kidney cortex 12", "Kidney cortex 15"]
  # bedpe directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  bedpe.dir: "GSE212910_RAW_HiC_bedpe"
  bedpe.ext: "GSM6560960_mustache_0.1_0.2_out.diffloops_in_cortex_2.bedpe"
  bedpe.names: ["HiC arches"]
  # bed directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  bed.dir: "GSE212908_ATAC_peaks"
  bed.ext: "GSE212908_RAM012_013_015_peak_masterlist.bed"
  bed.names: ["ATAC peaks"]
  # hic directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  hic.dir: "GSE212910_RAW_HiC"
  hic.ext: "GSM7749626_Cortex_partitioned_donor5_DM.hic"
  hic.names: ["HiC cortex"]
  # GWAS directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
  gwas.dir: "GWAScatalog_KidneyDisease"
  gwas.ext: "relocatedCol.tsv.gz"
  gwas.names: ["GWAS chronic kidney disease"]
  # categorical bed file.If empty type "  " or [""] in names.
  cat.file: "regulatory_elements_hg38.bed"
  cat.names: ["Regulatory Elements"]
  # file with chromosomes and centromeres coordinates
  chrom.cen: "chrom_centromeres_hg38.txt"
  # file with desired genome genes hgnc symbol and coordinates
  genes.hgnc: "hg38_hgnc_symbol_cleaned.bed"
```

It is suggested to **not change the configuration file name** and to keep it saved in the **same folder as the other app scripts and files**.

## Structure of the Genomic viewer interface

In the following section the different panels of **Genomic viewer** tool are described. 

### Main panel overview

When the app is opened the main panel will display. The main panel is divided into **three navigation bars**. 

![main_panel_wSections.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/main_panel_wSections.jpg)


1. **Left sidebar**: the left sidebar allows the user to set different options for the genomic region to be visualized: <a name="left-sidebar-anchor"></a>

	- **Choosing the genomic range:** The used can select the *chromosome name* (accepted names for hg38 are 1-22, X, Y), *start coordinate* and *end coordinate*. These values can be selected in different way: by directly typing in the corresponding field, by selecting a whole chromosome or a specific gene from the [right navigation bar](#rightnav-anchor) or by zooming-in and out from the [central panel](#zoom-in-and-out).
		   
	- **Select bigWig plots mode**: when there are bigWig tracks among the data files loaded by the user, one can choose if plotting bigWig signal as *Profile*, *Heatmap* or both *Profile and Heatmap* by choosing the desired option from the drop down menu. <a name="select-mode-anchor"></a>
	
	![select_bigwig_mode.jpg | center ](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/select_bigwig_mode.jpg) 
	
	- **GO button**: allows the user to initialize the plot with the selected options.  <a name="go-button-anchor"></a>
	
	- **Save button**: the *Save* button allows the user to download the displayed plot relative to the visualized genomic region in pdf format. This is only working for the genomic view plot and not for the plots displayed in the *[Stats tab](#Visualize-basic-statistics-analysis-for-the-loaded-data)*.   <a name="save-button-anchor"></a>


2. . **Central panel with plots and data**: the central panel is the most important. It allows the user to navigate across three different tabs: **Plot**, **Data** and **Stats**.   <a name="central-panel-anchor"></a>

	![navigation_tabs.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/navigation_tabs.jpg)
	
	- **[Plot](#Plot)**: here is where the main output of the app is shown. All the data that were loaded by the user through the *[Configuration file](#Configuration-file)* are plotted for the selected genomic region and according to the provided options. On the top left of the window, the exact coordinates of the displayed genomic regions are reported, and can be copy-pasted for external usage. The lowermost part of the window shows instead several options to **[Zoom-in and out](#Zoom-in-and-out)**.  <a name="plot-anchor"></a>
	  ![Plot_tab_wSections.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/Plot_tab_wSections.jpg)
	 
	- **[Data](#Visualize-raw-data-for-the-selected-genomic-range)**: this tab shows a preview (first 15 lines) of the original data that were used for plotting in the *[Plot tab](#plot-anchor)*. One table with the name of the corresponding dataset (as defined by the user in the *[Configuration file](#Configuration-file)*) is shown, together with a download button allowing the user to export the data of [Peaks bed](#Peaks-bed), [3D contacts arches bedpe](#3D-contacts-arches-bedpe), [Categorical bed](#Categorical-bed) and [GAWS summary statistics](#GWAS-summary-statistics) relative to the visualized genomic region.  <a name="data-tab-anchor"></a>
	  
	 ![data_tab.jpg | center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/data_tab.jpg)
	- **[Stats](#Visualize-basic-statistics-analysis-for-the-loaded-data)**: this tab displays some basic analysis calculated on the loaded data. The user can choose which **Stats plots** to run by pressing the **Run button** corresponding to each available stats section. Note that there are some data size limits above which the statistics will not be calculated to avoid too long computing times. When some datasets are not used in the stats calculation it will be indicated with a ***Warning message*** in the corresponding graph section. An example is shown in the figure below.

![stats_peak_counts_file_size_lim.jpg](https://github.com/sarlago/ShinyApps/blob/large-datasets/Genomic%20viewer%20Documentation/stats_peak_counts_file_size_lim.jpg)

The analysis that are available are:  <a name="stats-tab-anchor"></a>
		
		- the count of peaks (from [Peaks bed](#Peaks-bed) file) and arches number (from [3D contacts arches bedpe](#3D-contacts-arches-bedpe) file) in the selected genomic region compared to the total nr of peaks and arches of the corresponding sample; 
		
		- when both [Peaks bed](#Peaks-bed) and [3D contacts arches bedpe](#3D-contacts-arches-bedpe) files are available, the intersection of peaks in the two sets will be calculated and their numerosity plotted as ***upset plot*** for both the whole genome and the selected genomic range;
		
		- [Peaks bed](#Peaks-bed) file will be used for peaks annotation in the main functional genomic regions through the *[ChIPpeakAnno R package](https://bioconductor.org/packages/release/bioc/vignettes/ChIPpeakAnno/inst/doc/ChIPpeakAnno.html)*; 
		  
		- A **[circular packing](https://r-graph-gallery.com/circle-packing.html)** plot of categories classification and percentage abundance in the whole genome, and if present, in the user-selected genomic range. This plot will be generated merging the information from all the provided [Categorical bed](#Categorical-bed) files;
		
		- A *Manhattan plot* for the user selected genomic range with its position in the corresponding chromosome and the *Manhattan plot* of the entire chromosome. This will help to understand how ***significant SNPs*** are distributed in the chromosome and if the selected genomic region is an hotspot. When a whole chromosome is selected by the user, the zoom-in panel will not be displayed. ***ID of the SNPs*** that are above the significance threshold will be displayed in a smart way that avoids label overlap. The complete table with SNPs ID and the relative information for the user selected genomic range can be downloaded form the [Data tab](#data-tab-anchor). 
	 ![stats_tab_1.jpg | center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/stats_tab_1.jpg)
	   ![stats_tab_2.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/stats_tab_2.jpg)
	   <a name="manhattan-plot-anchor"></a>

3. **Right navigation bar**: this panel provides options for the automatic update of the genomic coordinates to visualize, as well as options to change the visualization mode for *[Categorical bed](#Categorical-bed) files* and the *[gene annotation track](#Required-files-for-genome-annotation)*.  <a name="rightnav-anchor"></a>

	- **Choose chromosome hover**: the top of the panel displays an overview of all the chromosomes relative to the active reference genome (**[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)** in the default case). This allows the user to easily select the coordinates of a whole chromosome for visualization of the loaded data tracks. By mouse hovering to single chromosomes in the plot a text is displayed below the graph indicating the corresponding chromosome name. By clicking on the chromosome in the plot the coordinates displayed in the [left sidebar](#left-sidebar-anchor) will automatically update and the **[Plot tab](#Plot,-Data-and-Stats-tab)** in the central window will update upon clicking the *[GO button](#go-button-anchor)*.
	
![choose_chromosome_hover.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/choose_chromosome_hover.jpg)

- **Search by gene**: the bottom of the panel displays a search menu in which the user can type gene names. The search box allows for autofill of the typed text with the matching gene names which the used can select from the displaying drop-down menu. By clicking on the corresponding gene name or typing in the complete name the coordinates displayed in the [left sidebar](#left-sidebar-anchor) will automatically update and the **[Plot tab](#Plot,-Data-and-Stats-tab)** in the central window will update upon clicking the *[GO button](#go-button-anchor)*. 

![search_by_gene.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/search_by_gene.jpg)

- **Select categories to expand**: the bottom of the panel displays a selection menu relative to eventual *[Categorical bed](#Categorical-bed)* files loaded by the user. In this field options will be available in the case when categorical bed files are loaded. By selecting one or more of the available file names from this menu, the user will select to expand the view of the categories belonging to the corresponding track in the central plot. Categories expansion can be relevant when genomic ranges annotated to different categories overlap. In this case the can be plotted on different lines and separated through the categories expansion option. <a name="select-categories-anchor"></a>


![expand_categories.jpg | center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/expand_categories.jpg)

- **Expand transcripts**: the lowermost option available from the right navigation panel allows to take action on the genome annotation track relative to the active reference genome. In the default visualization *Gene tracks* are collapsed. By checking the *Expand transcript* box genes annotations relative to the visualize genomic range will be expanded to visualize all the annotated transcripts. <a name="expand-transcript-anchor"></a>

![expand_transcript.jpg | center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/expand_transcript.jpg)

## Usage

The previous sections already describe all the main functionalities of the **Genomic viewer**. In this section it will be described more in details the **usage of the tool** and the **different options** that are tunable by the user will be covered in a more **practical aspect**.

### Setting up the input datasets

The first thing to do before starting the **Genomic viewer** app is to fill in the [Configuration file](#Configuration-file) with all the required information about the local *path to the files*, the *files pattern* and *user-defined name*s to be employed by the app. Remember that by default **Genomic viewer** works on the **[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)** reference genome, so the genomic annotation files for this reference genome are already available and it is sufficient to indicate their path in the [Configuration file](#Configuration-file). In case a different reference genome will be used, the annotation files must be prepared by the user as described in the [Reference genome](#Reference-genome) section. 
### Selecting the genomic region to visualize

Once the [Configuration file](#Configuration-file) is ready the app can be started. It will automatically show a test genomic range (chr1: 28000000-28500000), the corresponding plot, data and stats will however only be displayed only when the user clicks the *[GO button](#go-button-anchor)*. If the user wants to visualize its own genomic region to visualize there are different options described below.

#### Manual entering of coordinates

The most basic way to insert specific coordinates to be visualized is by manually typing in the *chromosome name*, *start* and *end* coordinate. This is feasible form the [left sidebar](#left-sidebar-anchor). The [Plot, Data and Stats tab](#Plot,-Data-and-Stats-tab) will update with the new coordinates only upon clicking on the *[GO button](#go-button-anchor)*. Note that in the *Choose chromosome* field just the number or letter corresponding to the intended chromosome must be typed without being preceded by the *'chr'* string (e.g. *1* and not *chr1* or *X* and not *chrX*).

![manual_entering_coord.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/manual_entering_coord.jpg)
#### Chromosome hover

In case the user wants to visualize an entire chromosome the [right navigation bar](#rightnav-anchor) reports an interactive plot from which the user can mouse hover and click on the desired chromosome. The coordinates displayed in the [left sidebar](#left-sidebar-anchor) will update according to the start and end coordinate of the selected chromosome. The [Plot, Data and Stats tab](#Plot,-Data-and-Stats-tab) will be updated only upon clicking the *[GO button](#go-button-anchor)*. 
#### Search by gene

In case the user wants to visualize a specific gene, it can be queried by mean of the ***gene name***. Gene names can be entered from the *Search by gene* bar in the [right navigation bar](#rightnav-anchor). When the user starts to type the gene name a drop down menu will appear with the possible options matching the typed string. After selecting or typing the complete gene name, the [Plot, Data and Stats tab](#Plot,-Data-and-Stats-tab) will update upon clicking the *[GO button](#go-button-anchor)*. 

#### Zoom-in and out

Another way to select a specific genomic window to be visualized is by starting from a position and next gradually **[Zoom-in and out](#Zoom-in-and-out)** to adjust the focus on specific features of interest. This is feasible from the bottom part of the central **Plot** panel. 

![zoom_bar_wSections.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/zoom_bar_wSections.jpg)

The **zoom bar** offers different modes for zooming-in and out as illustrated in the figure above:
- **Static plot zoom**: The '+', '-' and 'RESET' buttons in the bottom right corner of the genomic view plot allows to zoom-in and out the plot without changing the visualized genomic coordinates. The resolution of the plot will not change by zooming-in since it is a **vectorial image**. The 'RESET' button allows to restore the initial plot size. The static zoom is also a **pan-zoom**, meaning that the user can move the image by hold-clicking on it. Note that this type of zoom is just for dynamic visualization within the app and will not be applied on the **[saved plot](#Downloading-plots-and-data)**. In addition the ***static zoom controller*** will be disabled when the cumulative size of the files to plot is greater than 2 GB and the selected range to plot larger than 500 kbp, this is because in such condition the visualized image is not **vectorial**, but is a **jpeg** to allow for faster and more dynamic image visualization. The **[saved plot](#Downloading-plots-and-data)** will instead keep vectorial resolution. <a name="static-zoom-anchor"></a>

- **Drag an drop bar**: below the static zoom button there is a draggable bar consisting in an orange rectangle, that matches the plotted genomic range, and grey flanking representing the ***25% extensions*** of the visualized range. The numbers below the bar report the coordinates in bp. By mouse drag-and-drop in the orange rectangle the user can zoom-in in the visualized genomic area, while by mouse drag-and-drop in the grey area the user can either zoom-out enlarging the actual genomic range or zoom-in in the flanking range. The maximum allowed zoom-in is **500 bp**, further zoom will not be allowed. Zooming by drag-and-drop is **limited to the selected chromosome coordinates**. The coordinates of the zoomed region will be automatically displayed in the [left sidebar](#left-sidebar-anchor), but the [Plot, Data and Stats tab](#Plot,-Data-and-Stats-tab) will be updated just upon clicking the *[GO button](#go-button-anchor)*. <a name="drag-drop-anchor"></a>

- **Proportional zoom buttons**: the lowermost zoom option in the **Zoom bar** allows the user to **proportionally enlarge or restrict** the visualized genomic range, by always keeping the initial region in the middle of the plotted area. Different buttons are available to zoom-in or out by **1x**, **5x** or **10x**. The user can click once or several time on each button, at every click the coordinates displayed in the [left sidebar](#left-sidebar-anchor) will update. The [Plot, Data and Stats tab](#Plot,-Data-and-Stats-tab) will only reload once the user clicks the [GO button](#go-button-anchor). The maximum allowed zoom-in is **500 bp**, further zoom will not be allowed. Zooming by drag-and-drop is **limited to the selected chromosome coordinates**.
### Plot, Data and Stats tab

The main functionalities of the **Genomic viewer** can be accessed through the three tabs in the [central panel](#central-panel-anchor). These allow respectively to visualize the genomic and annotation tracks loaded by the user through the [Configuration file](#Configuration-file) with few options to adapt the output, to display and download the raw data corresponding to a user-selected genomic range, and to obtain an overview of some feature relative to the different tracks type.
#### Genomic view plot of the selected genomic range

The principal output of the app is the **genomic view plot**. This will be generated using the track files selected by the user in the [Configuration file](#Configuration-file). The tracks will be plotted after [Selecting the genomic region to visualize](#Selecting-the-genomic-region-to-visualize) and can be updated at any time. Tracks height is automatically scaled depending on the number of loaded datasets. 
Depending on the type of track and the wideness of the selected genomic region, the tool behaves differently to improve the image readability and computation speed. It follows a description of all the single tracks that can be displayed, if available which are the options that the user has to modify their visualization, and how the tool calculates the output depending on the size of the genomic range to be visualized.
##### 3D contacts Heatmap Matrix

File of the *.hic* format are used to plot [HiC and 3D contact matrices](#HiC-and-3D-contact-matrices). There are several methods for plotting the matrices, in the **Genomic viewer** triangular matrices are plotted as *triangular matrices*. This type of data and consequently the resulting plot can be very heavy, therefore different resolutions can be set to obtain a compromise between the detailed to be visualized form the data and the computational/output expensiveness. To this aim the **Genomic viewer** automatically applies different data resolutions based on the size of the genomic regions that is requested to plot. In particular:
- for genomic ranges larger than 5 Mbp the binning resolution will be of 500 kbp;
- for genomic ranges > 100 kbp and ≤ 5 Mbp the binning resolution will be of 100 kbp;
- for genomic ranges > 25 kbp and ≤ 100 kbp the binning resolution will be of 25 kbp;
- for genomic ranges ≥ 15 kbp and ≤ 25 kbp the binning resolution will be of 15 kbp (this must be compatible with the loaded data resolution, otherwise will not be plotted);
- for genomic ranges < 15 kbp the 3D contact matrix will not be plotted since it approaches the minimal resolution allowed by the data and will not have a significant biological meaning.

The image below shows some examples of HiC heatmaps plotted at different resolutions based on the genomic range.

![3D_matrix_resolutions.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/3D_matrix_resolutions.jpg)

##### bigWig profile and heatmap tracks

File of the *.bigwig* format are used to plot [ChIP-seq, ATAC-seq, RNA-seq and several other NGS datasets](#ChIP-seq,-ATAC-seq,-RNA-seq-or-any-other-bigWig). The most common way in which *bigwig* files are plotted is as signal intensity ***profile plots***, however in some cases it can be useful to plot them as ***heatmaps***. The **Genomic viewer** allows both [visualization modes](#select-mode-anchor), plus it allows to plot the same track simultaneously as *profile* or *heatmap*. *Bigwig* files are thought for data visualization and contain a score that is proportional to the signal intensity for defined genomic bins. This score information is either plot as signal profile (histogram-like, built-in function of **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotSignal.html)**) or transformed in a color-scale employed to generate a heatmap (**[plotgardener ranges](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html)**). 
Like the [3D contacts Heatmap Matrix](#3D-contacts-Heatmap-Matrix) plots, also the *bigwig* files normally bins genomic windows as a compromise between resolution and computational expenses. To speed up the dynamic visualization of the tracks in the **Genomic viewer** without loosing information, both ***profile plots*** and ***heatmaps*** generated from *bigwig* files are binned depending on the size of the genomic range selected by the user:
- for genomic ranges ≥ 200 Mbp the binning resolution will be of 1 Mbp;
- for genomic ranges ≥ 50 Mbp and < 200 Mbp the binning resolution will be of 500 kbp;
- for genomic ranges ≥ 5 Mbp and < 50 Mbp the binning resolution will be of 50 kbp;
- for genomic ranges ≥ 100 kbp and < 5 Mbp the binning resolution will be of 5 kbp;
- for  genomic ranges < 100 kbp no binning is applied, preserving the resolution of the original input file.

The image below shows some examples of *profile* plots and *heatmaps* from the same input *bigwig* file, plotted at different resolutions based on the genomic range.

![bigwig_binning.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/bigwig_binning.jpg)

When multiple *bigwig* files are loaded and must be compared, it is good practice to uniform the y-scale for all samples. In the **Genomic viewer** the y-scale for bigwigs is automatically auto-scaled based on the maximal *y* value of the most intense sample, every time the selected genomic range is updated. When multiple *bigwig* files are loaded a different color is automatically applied to every sample, when plotted in the *profile mode*
##### Peaks bed file tracks

[Peak](#Peaks-bed) files are normally stored in the *.bed* format. These files are plotted as ranges by exploiting the corresponding built-in function from **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html)**. When multiple *peaks .bed* files are loaded by the user a different color is automatically applied to every sample. There is no customization option for this type of track and no binning is normally necessary. However, when the plotted range is larger than 10 Mbp peaks are displayed as **density plots** to improve readability, informativity and reduce image size.
An example of how peak file track appears in the **Genomic viewer** is reported in the figure below:

![peak_bed_track.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/peak_bed_track.jpg)

![peak_bed_track_density.jpg|center](https://github.com/sarlago/ShinyApps/blob/large-datasets/Genomic%20viewer%20Documentation/peak_bed_track_density.jpg)

##### Categorical bed file tracks

In addition to *peaks ranges* *.bed* files can also be used to mark genomic regions that belong to specific categories, which can be annotated with some external tool or database, or defined by he user. The **Genomic viewer** allows to load [categorical .bed](#Categorical-bed) files and plot them by exploiting the same built-in function from **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html)** that is used for standard [Peaks bed](#Peaks-bed). 
In **Genomic viewer**, every category that is found in the [Categorical bed](#Categorical-bed) file is associated to a different color and represented in a legend beside that corresponding track in the plot. Since it can happen that the genomic ranges belonging to different categories overlap, or that a same genomic range belongs to two categories, **Genomic viewer** has the possibility to **[expand or collapse](#select-categories-anchor)** the categories.
An example of *collapsed* and *expanded* categorical bed tracks is reported in the figure below:

![collapsed_expanded_categories.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/collapsed_expanded_categories.jpg)
##### 3D contact arches 

In addition to contact matrices and heatmap, 3D contacts can also be represented as ***arches*** connecting the 2D genomic positions that are touching. This type of representation is stored in [bedpe files](#3D-contacts-arches-bedpe) and is plotted in **Genomic viewer** through a dedicated **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotPairsArches.html)** built-in function. Some [bedpe files](#3D-contacts-arches-bedpe) also have a *score* column containing a value that is proportional to the *strength/likelihood* of the contact. In this latter case the corresponding arch thickness will be proportional to the contact score.
There is no customization option for this type of track and no binning is normally necessary.
An example of how *3D contact arches bedpe* file track appears in the **Genomic viewer** is reported in the figure below:

![3D_contact_arches.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/3D_contact_arches.jpg)
##### GWAS Manhattan track

**[GWAS summary statistics](#GWAS-summary-statistics)** files can be exploited to generate **[Manhattan plots](#manhattan-plot-anchor)** for the identification of trait-associated SNPs. Once the **[GWAS summary statistics](#GWAS-summary-statistics)** file has been correctly arranges by the user, the **[Manhattan plots](#manhattan-plot-anchor)** are generated in the **Genomic viewer** through the dedicated **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotManhattan.html)** built-in function. In this plot every SNP is represented by a dot, which color is representative of the p-value of its association with specific traits, depending on the dataset. A **color-scale legend** is reported beside to the track plot and a dashed line indicate the *significance threshold*.
There is no customization option for this type of track and no binning is normally necessary, however an overview of the visualized chromosome with a zoom-in on the selcted region and most significant SNPs label are reported in the [Stats tab](#stats-tab-anchor). 
An example of how  **[Manhattan plots](#manhattan-plot-anchor)** track appears in the **Genomic viewer** is reported in the figure below:

![Manhattan_plot_track.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/Manhattan_plot_track.jpg)
##### Genes annotation track

The lowermost part of the main plot output consists of different layers of genes annotations. By default the genes annotation is plotted for the [GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/) reference genome exploiting built-in **plotgardener** functions.  The **genes annotation track** height is fixed and will not be scale4d depending on the number of loaded datasets. The available options for this type of track are:

1. The representation of **[genes and genes structures](https://phanstiellab.github.io/plotgardener/reference/plotGenes.html)** (promoters, introns, exons) in the user-selected genomic range. By default **plotgardener** plots in two different lines and colors genes that are encoded on the positive and negative strand. Through the [right navigation bar](#rightnav-anchor), the user can optionally decide to [expand transcripts](#expand-transcript-anchor), which means that instead of visualizing the largest form of each ***gene*** in the displayed genomic range (default option), the separate ***transcript isoforms*** are plotted. The two options are represented in the image below:
   ![genes_and_transcripts.jpg](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/genes_and_transcripts.jpg) <a name="genes-track-anchor"></a>
   
   Another relevant feature of the **genes annotation track** is that when the genomic range selected for visualization is too wide (> 10 Mbp), individual genes are not plotted but are substituted by a **density plot** of genes density. This solution allows to obtain faster computation of the genes track and provides a more relevant biological information, since at that resolutions individual genes could not be distinguished. Below is an example of how **genes density plot** appear at large genomic ranges visualization:
      ![gene_density.jpg|center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/gene_density.jpg)
    The ***gene density*** visualization mode does not allow the user to apply the *[Expand transcript](#expand-transcript-anchor)* option.
   
3. A **[Genome label](https://phanstiellab.github.io/plotgardener/reference/annoGenomeLabel.html)** track is always reported below of the [genes and genes structure](#genes-track-anchor) track. This is a light representation of the genomic coordinates in *bp* and the *chromosome name* corresponding to the visualized region. An example of it is indicated in the [image](#genes-track-anchor) above. 
   
4. A **[Chromosome ideogram](https://phanstiellab.github.io/plotgardener/reference/plotIdeogram.html)** of the chromosome corresponding to the selected genomic region is always plotted below of all the other genomic annotation tracks. A *red highlight* indicates the position of the plotted genomic range in the chromosome, and two dashed lines connect the highlight to the below [zooming bar](#drag-drop-anchor). An example of this visualization is shown in the image below: 
   
   ![chromosome_ideogram.jpg| center](https://github.com/sarlago/ShinyApps/blob/main/Genomic%20viewer%20Documentation/chromosome_ideogram.jpg)
   
#### Visualize raw data for the selected genomic range

The **[Data](#data-tab-anchor)** tab in the [main central panel](#main-panel-overview) provides an overview (first 15 lines) of the tables containing the raw data of the tracks that are used to generate the [genomic tracks plot](#plot-anchor). 
A preview of the tables can be visualized for: [Peaks bed](#Peaks-bed), [3D contacts arches bedpe](#3D-contacts-arches-bedpe); [Categorical bed](#Categorical-bed) and [WAS summary statistics](#GWAS-summary-statistics). 
All the subset tables relative to the visualized genomic region can be downloaded from this tab, as described in the section: *[Download of raw data of the plotted genomic range](#Download-of-raw-data-of-the-plotted-genomic-range)*.
#### Visualize basic statistics analysis for the loaded data

The **[Stats](#stats-tab-anchor)** tab in the [main central panel](#main-panel-overview) provides some basic analysis of the datasets loaded by the user.  The different plots that are generated in this tab are described in more details in the **[Stats](#stats-tab-anchor)** section. In brief, here are shown: 

- A **barplots** for peaks (bed files) and arches (bedpe files) number in total and in the user-selected genomic region; 

- An **upset plots** of the intersection between peaks or arches (bed or bedpe files) of different samples, and of the intersection between peaks and arches.

- A **piechart** showing peaks annotations (bed files) across genomic functional regions, produced through the *[ChIPpeakAnno](https://bioconductor.org/packages/release/bioc/vignettes/ChIPpeakAnno/inst/doc/ChIPpeakAnno.html)* R package. This plot is only generated for peaks in the whole genome, without subsetting the user-selected genomic range.
  
- A **[circular packing](https://r-graph-gallery.com/circle-packing.html)** plot which reports the percentage abundance of the features in the provided [Categorical bed](#Categorical-bed) files for either the whole genome or, if any, the user-selected genomic range. This plot consists in a series of circles which radius is proportional to the amount of elements classified according to the reported categories. Circles are also organized hierarchically, allowing to evaluate different types of classifications in the same plot. This is particularly useful when more than one [Categorical bed](#Categorical-bed) file is provided.

- A **[Manhattan plot](#manhattan-plot-anchor)** of the chromosome relative to the user-selected region with the IDs of the significant SNPs. When the selected region is smaller than the entire chromosome, a zoom-in of the region with the IDs of the significant SNPs is displayed. This allows the user to evaluate the relevance of the features in the selected regions within the context of the surrounding genomic elements.

The user can choose which **Stats plots** to run by pressing the **Run button** corresponding to each available stats section. Note that there are some data size limits above which the statistics will not be calculated to avoid too long computing times. When some datasets are not used in the stats calculation it will be indicated with a ***Warning message*** in the corresponding graph section. 

### Downloading plots and data

In the following section are described the possibilities for downloading plots and data from the **Genomic viewer** interface. The downloaded image has a maximum size of 10"x8" and the plotted tracks height, except of the genomic annotation track, is scaled depending on the number of loaded datasets.

#### Download of the genomic view plot

The **[Genomic view plot of the selected genomic range](#Genomic-view-plot-of-the-selected-genomic-range)** is the main output of **Genomic viewer** interface and can be easily downloaded from the *[Save button](#save-button-anchor)* in the [left sidebar](#left-sidebar-anchor). By clicking the button, the user can choose the destination folder and the name of the file. The plot is automatically saved in the **vectorial pdf** format. Any [static zoom](#static-zoom-anchor) that is applied to the graph through the interface is just for dynamic visualization and will not be applied to the saved plot. When the visualized image of the selected genomic range is plotted as a **jpeg** (because the range exceeds 500 kbp and the cumulative size of the input files is larger than 2 GBs) the saved plot will still be a **vectorial pdf**. 

#### Download of raw data of the plotted genomic range

In the **[Data](#data-tab-anchor)** tab in the [main central panel](#main-panel-overview) is visualized a preview of the raw datasets that are used to generate the **genomic view plot**, subset to the user-selected genomic range. The subset data tables can be downloaded as tab separated files with the same extension as the originally loaded files though a specific **Download button** followed by the names of the dataset as provided by the user in the [configuration file](#Configuration-file). By clicking on the **Download button** the user can choose the destination folder and the name of the file. By default the files will be named with the name of the corresponding input data file as provided by the user in the [configruation file](#Configuration-file)
#### Saving basic statistics plots

The plots displaying basic analysis of the data that are shown in the **[Stats](#stats-tab-anchor)** tab in the [main central panel](#main-panel-overview) are thought to provide to the user a quick overview of some easy information of the loaded data. They are not meant for direct external use, therefore they can not be directly downloaded through a dedicated button to save them as **vectorial** or **high quality** images. However the user can easily copy-and-paste the graphs images for external use.
### R session info

Below is a **Session information** summary of ***R version*** and the used ***packages*** employed by **Genomic viewer**.

```r
R version 4.4.3 (2025-02-28 ucrt)
Platform: x86_64-w64-mingw32/x64
Running under: Windows 11 x64 (build 22631)

Matrix products: default


locale:
[1] LC_COLLATE=English_United States.utf8  LC_CTYPE=English_United States.utf8   
[3] LC_MONETARY=English_United States.utf8 LC_NUMERIC=C                          
[5] LC_TIME=English_United States.utf8    

time zone: Europe/Berlin
tzcode source: internal

attached base packages:
[1] stats4    stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 [1] ggchicklet_0.6.0                         igraph_2.1.4 
 [3] ggraph_2.2.1                             ggpubr_0.6.0   
 [5] dplyr_1.1.4                              ComplexUpset_1.3.3 
 [7] spiky_1.12.0                             Rsamtools_2.22.0 
 [9] Biostrings_2.74.1                        XVector_0.46.0 
[11] rtracklayer_1.66.0                       ChIPpeakAnno_3.40.0 
[13] ggplot2_3.5.2                            AnnotationHub_3.14.0  
[15] BiocFileCache_2.14.0                     dbplyr_2.5.0 
[17] TxDb.Hsapiens.UCSC.hg38.knownGene_3.20.0 GenomicFeatures_1.58.0  
[19] GenomicRanges_1.58.0                     GenomeInfoDb_1.42.3  
[21] org.Hs.eg.db_3.20.0                      AnnotationDbi_1.68.0
[23] IRanges_2.40.1                           S4Vectors_0.44.0  
[25] Biobase_2.66.0                           BiocGenerics_0.52.0  
[27] plotgardener_1.12.0                      shinycssloaders_1.1.0 
[29] paletteer_1.6.0                          svgPanZoom_0.3.4  
[31] svglite_2.1.3                            bslib_0.9.0  
[33] shiny_1.10.0                            

loaded via a namespace (and not attached):
  [1] splines_4.4.3               later_1.4.2                 prismatic_1.1.2 
  [4] bamlss_1.2-5                BiocIO_1.16.0               bitops_1.0-9  
  [7] ggplotify_0.1.2             filelock_1.0.3              R.oo_1.27.0 
 [10] tibble_3.2.1                polyclip_1.10-7             graph_1.84.1 
 [13] XML_3.99-0.18               lifecycle_1.0.4             httr2_1.1.2  
 [16] pwalign_1.2.0               rstatix_0.7.2               lattice_0.22-7 
 [19] ensembldb_2.30.0            MASS_7.3-65                 backports_1.5.0 
 [22] magrittr_2.0.3              sass_0.4.10                 rmarkdown_2.29
 [25] jquerylib_0.1.4             yaml_2.3.10                 httpuv_1.6.16  
 [28] sp_2.2-0                    cowplot_1.1.3               DBI_1.2.3    
 [31] RColorBrewer_1.1-3          abind_1.4-8                 zlibbioc_1.52.0   
 [34] R.utils_2.13.0              purrr_1.0.4                 AnnotationFilter_1.30.0    
 [37] RCurl_1.98-1.17             yulab.utils_0.2.0           tweenr_2.0.3 
 [40] rappdirs_0.3.3              GenomeInfoDbData_1.2.13     ggrepel_0.9.6
 [43] codetools_0.2-20            DelayedArray_0.32.0         ggforce_0.4.2 
 [46] xml2_1.3.8                  tidyselect_1.2.1            futile.logger_1.4.3 
 [49] UCSC.utils_1.2.0            farver_2.1.2                viridis_0.6.5  
 [52] universalmotif_1.24.2       matrixStats_1.5.0           GenomicAlignments_1.42.0   
 [55] jsonlite_2.0.0              multtest_2.62.0             tidygraph_1.3.1 
 [58] Formula_1.2-5               survival_3.8-3              systemfonts_1.2.2
 [61] tools_4.4.3                 progress_1.2.3              ragg_1.4.0  
 [64] strawr_0.0.92               MBA_0.1-2                   BlandAltmanLeh_0.3.1
 [67] Rcpp_1.0.14                 glue_1.8.0                  gridExtra_2.3  
 [70] SparseArray_1.6.2           xfun_0.52                   mgcv_1.9-3  
 [73] MatrixGenerics_1.18.1       withr_3.0.2                 formatR_1.14  
 [76] BiocManager_1.30.25         fastmap_1.2.0               rhdf5filters_1.18.1 
 [79] digest_0.6.37               R6_2.6.1                    mime_0.13   
 [82] gridGraphics_0.5-1          textshaping_1.0.0           colorspace_2.1-1 
 [85] biomaRt_2.62.1              RSQLite_2.3.9               R.methodsS3_1.8.2 
 [88] config_0.3.2                tidyr_1.3.1                 generics_0.1.3 
 [91] data.table_1.17.0           htmlwidgets_1.6.4           graphlayouts_1.2.2 
 [94] prettyunits_1.2.0           InteractionSet_1.34.0       httr_1.4.7  
 [97] S4Arrays_1.6.0              regioneR_1.38.0             pkgconfig_2.0.3 
[100] gtable_0.3.6                rsconnect_1.3.4             blob_1.2.4 
[103] htmltools_0.5.8.1           carData_3.0-5               RBGL_1.82.0 
[106] plyranges_1.26.0            ProtGenerics_1.38.0         scales_1.4.0 
[109] png_0.1-8                   distributions3_0.2.2        knitr_1.50 
[112] lambda.r_1.2.4              rstudioapi_0.17.1           rjson_0.2.23 
[115] coda_0.19-4.1               nlme_3.1-168                curl_6.2.2  
[118] cachem_1.1.0                rhdf5_2.50.2                stringr_1.5.1  
[121] BiocVersion_3.20.0          parallel_4.4.3              restfulr_0.0.15  
[124] pillar_1.10.2               grid_4.4.3                  vctrs_0.6.5   
[127] promises_1.3.2              car_3.1-3                   xtable_1.8-4  
[130] evaluate_1.0.3              VennDiagram_1.7.3           mvtnorm_1.3-3   
[133] cli_3.6.4                   compiler_4.4.3              futile.options_1.0.1
[136] rlang_1.1.6                 crayon_1.5.3                ggsignif_0.6.4  
[139] labeling_0.4.3              rematch2_2.1.2              fs_1.6.6  
[142] stringi_1.8.7               viridisLite_0.4.2           BiocParallel_1.40.2 
[145] lazyeval_0.2.2              Matrix_1.7-3                BSgenome_1.74.0 
[148] hms_1.1.3                   patchwork_1.3.0             bit64_4.6.0-1  
[151] Rhdf5lib_1.28.0             KEGGREST_1.46.0             SummarizedExperiment_1.36.0
[154] bsicons_0.1.2               fontawesome_0.5.3           broom_1.0.8          
[157] memoise_2.0.1               bit_4.6.0
```
