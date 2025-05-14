
```table-of-contents

```

## Overview
This **genomic viewer** app has been developed to allow the visualization of multi-omics data of several kind. It has been implemented in **[[R]]** using **[[Shiny]]** and [[Plotgardener for flexible genomic screen generation]] packages.  The application allows to generate and export genomic view plots as well as download tables with datasets on selected genomic regions and perform some basic statistics and additional plots providing an overview of the input data. 


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
i) **limit the zoom area** based on the selected chromosome length ([[#Zoom-in and out]]);
ii) plotting whole chromosome regions selected by the user from the **Choose chromosome** right panel ([[#Chromosome hover]]).

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

A .bed file that contains the information about chromosome, start, end, strand and the HGNC symbol or any other gene nomenclature desired by the user to be visualized for the gene search option. This file is used instead for allowing the **[[#Search by gene]]** option available in the **Choose chromosome** right panel.
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
3D contacts can be represented not only as a heatmap or matrix, but as well as arches that join two distal genomic regions that are found in contact. This type of information is stored in the [.bedpe file format](https://bedtools.readthedocs.io/en/latest/content/general-usage.html#bedpe-format).
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
In addition to the standard .bed file, **Genomic viewer** also accepts categorical .bed which are structured as the [[#Peaks bed]] but have an additional required column assigning the corresponding genomic range to a category. In addition, categorical bed columns are names, as in the example below. Categorical bed can be used for example to classify peaks or functional genomic elements. For instance, several **functional elements** coordinates can be downloaded from [**UCSC Table Browser**](https://genome.ucsc.edu/cgi-bin/hgTables) and arranged in a single categorical bed file through the script [*generate_categorical_bed.Rmd](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/generate_categorical_bed.Rmd>)*. The resulting file (*[regulatory_elements_hg38.bed](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/regulatory_elements_hg38.bed>))* looks like this:

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
To allow users to provide locally saved dataset to the **genomic viewer** without an heavy graphical interface, an **[[R configuration files (YAML)]]** has been set up. The configuration file (*[Shiny_wzoom_config_hover.yml](<file:///C:/Users/sarlago/Documents/R scripts/Shiny/ShinyLoadYML/ShinyApps/ShinyApps_hover/Shiny_wzoom_config_hover.yml>)*) is structured as shown below and allows the user to load any number of datasets for all the accepted data types. Note that when some of the specified entries is absent the corresponding field must be filled with an empty string " " or vector '[""]' as specified in the file comments.

```yml
---

default:

    # Set here the parameters related to the input files path and extensions
  # Data directory
  data.dir: "local/path/to/files/folder/"
  # bigWig directory and files final pattern or complete name (can correspond to one or more tracks), ordered file name to visualize. If empty type " " or [""] in names.
  bw.dir: "GSE212908_RAW_ATAC_bigwig"
  bw.ext: "treat_pileup.bw"
  bw.names: ["Kidney cortex 12", "Kidney cortex 15"]
  # bedpe directory and files final pattern, ordered file name to visualize. If empty type " " or [""] in names.
  bedpe.dir: "GSE212910_RAW_HiC_bedpe"
  bedpe.ext: "GSM6560960_mustache_0.1_0.2_out.diffloops_in_cortex_2.bedpe"
  bedpe.names: ["HiC arches"]
  # bed directory and files final pattern, ordered file name to visualize. If empty type " " or [""] in names.
  bed.dir: "GSE212908_ATAC_peaks"
  bed.ext: "GSE212908_RAM012_013_015_peak_masterlist.bed"
  bed.names: ["ATAC peaks"]
  # hic directory and files final pattern, ordered file name to visualize. If empty type " " or [""] in names.
  hic.dir: "GSE212910_RAW_HiC"
  hic.ext: "GSM7749626_Cortex_partitioned_donor5_DM.hic"
  hic.names: ["HiC cortex"]
  # GWAS directory and files final pattern, ordered file name to visualize. If empty type " " or [""] in names.
  gwas.dir: "GWAScatalog_KidneyDisease"
  gwas.ext: "relocatedCol.tsv.gz"
  gwas.names: ["GWAS chronic kidney disease"]
  # categorical bed file.If empty type " " or [""] in names.
  cat.file: "regulatory_elements_hg38.bed"
  cat.names: ["Regulatory Elements"]
  # file with chromosomes and centromeres coordinates
  chrom.cen: "chrom_centromeres_hg38.txt"
  # file with desired genome genes hgnc symbol and coordinates
  genes.hgnc: "hg38_hgnc_symbol_cleaned.bed"
```

It is suggested to **not change the configuration file name** and to keep it saved in the **same folder as the other app scripts and files**.

## Output results


## Structure of the Genomic viewer interface

In the following section the different panels of **Genomic viewer** tool are described. 

### Main panel overview
When the app is opened the main panel will display. The main panel is divided into **three navigation bars**. 

![[main_panel_wSections.jpg]]


1. **Left sidebar**: the left sidebar allows the user to set different options for the genomic region to be visualized: 

	- **Choosing the genomic range:** The used can select the *chromosome name* (accepted names for hg38 are 1-22, X, Y), *start coordinate* and *end coordinate*. These values can be selected in different way: by directly typing in the corresponding field, by selecting a whole chromosome or a specific gene from the [[#^f30e7c|right navigation bar]], or by zooming-in and out from the [[#^af61fe|central panel]].
	 ^f6fb72
	- **Select bigWig plots mode**: when there are bigWig tracks among the data files loaded by the user, one can choose if plotting bigWig signal as *Profile*, *Heatmap* or both *Profile and Heatmap* by choosing the desired option from the drop down menu. ^ab5d51
	
	![[select_bigwig_mode.jpg | center ]] ^57c39c
	
	- **GO button**: allows the user to initialize the plot with the selected options.
	 ^dbc4a3
	- **Save button**: the *Save* button allows the user to download the displayed plot relative to the visualized genomic region in pdf format. This is only working for the genomic view plot and not for the plots displayed in the *[[#Visualize basic statistics analysis for the loaded data|Stats tab]]*.
	
2. . **Central panel with plots and data**: the central panel is the most important. It allows the user to navigate across three different tabs: **Plot**, **Data** and **Stats**. ^af61fe

	![[navigation_tabs.jpg]]
	
	- **[[#Plot]]**: here is where the main output of the app is shown. All the data that were loaded by the user through the *[[#Configuration file]]* are plotted for the selected genomic region and according to the provided options. On the top left of the window, the exact coordinates of the displayed genomic regions are reported, and can be copy-pasted for external usage. The lowermost part of the window shows instead several options to **[[#Zoom-in and out]]**.  ^76719c
	  ![[Plot_tab_wSections.jpg]]
	 
	- **[[#Visualize raw data for the selected genomic range|Data]]**: this tab shows a preview (first 15 lines) of the original data that were used for plotting in the *[[#^76719c|Plot tab]]*. One table with the name of the corresponding dataset (as defined by the user in the *[[#Configuration file]]*) is shown, together with a download button allowing the user to export the data of [[#Peaks bed]], [[#3D contacts arches bedpe]] and [[#GWAS summary statistics]] relative to the visualized genomic region.
	 ^7c20c9
	 ![[data_tab.jpg | center]]
	- **[[#Visualize basic statistics analysis for the loaded data|Stats]]**: this tab displays some basic analysis calculated on the loaded data. The analysis that are available are:  ^95ac88
		
		- the count of peaks (from [[#Peaks bed]] file) and arches number (from [[#3D contacts arches bedpe]] file) in the selected genomic region compared to the total nr of peaks and arches of the corresponding sample; 
		
		- when both [[#Peaks bed]] and [[#3D contacts arches bedpe]] files are available, the intersection of peaks in the two sets will be calculated and their numerosity plotted for both the whole genome and the selected genomic range;
		
		- [[#Peaks bed]] file will be used for peaks annotation in the main functional genomic regions through the *[ChIPpeakAnno R package](https://bioconductor.org/packages/release/bioc/vignettes/ChIPpeakAnno/inst/doc/ChIPpeakAnno.html)*;
		
		- A *Manhattan plot* for the user selected genomic range with its position in the corresponding chromosome and the *Manhattan plot* of the entire chromosome. This will help to understand how ***significant SNPs*** are distributed in the chromosome and if the selected genomic region is an hotspot. When a whole chromosome is selected by the user, the zoom-in panel will not be displayed. ***ID of the SNPs*** that are above the significance threshold will be displayed in a smart way that avoids label overlap. The complete table with SNPs ID and the relative information for the user selected genomic range can be downloaded form the [[#^7c20c9|Data tab]]. 
	 ![[stats_tab_1.jpg | center]]
	  ![[stats_tab_2.jpg | center]] ^18d054

3. **Right navigation bar**: this panel provides options for the automatic update of the genomic coordinates to visualize, as well as options to change the visualization mode for *[[#Categorical bed]] files* and the *[[#Required files for genome annotation|Gene annotation track]]*.  ^d610b2

	- **Choose chromosome hover**: the top of the panel displays an overview of all the chromosomes relative to the active reference genome (**[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)** in the default case). This allows the user to easily select the coordinates of a whole chromosome for visualization of the loaded data tracks. By mouse hovering to single chromosomes in the plot a text is displayed below the graph indicating the corresponding chromosome name. By clicking on the chromosome in the plot the coordinates displayed in the [[#^f6fb72|left sidebar]] will automatically update and the **[[#Plot, Data and Stats tab|Plot tab]]** in the central window will update upon clicking the *[[#^dbc4a3|GO button]]*. ^f30e7c
	
![[choose_chromosome_hover.jpg]]

- **Search by gene**: the bottom of the panel displays a search menu in which the user can type gene names. The search box allows for autofill of the typed text with the matching gene names which the used can select from the displaying drop-down menu. By clicking on the corresponding gene name or typing in the complete name the coordinates displayed in the [[#^f6fb72|left sidebar]] will automatically update and the **[[#Plot, Data and Stats tab|Plot tab]]** in the central window will update upon clicking the *[[#^dbc4a3|GO button]]*. 

![[search_by_gene.jpg]]

- **Select categories to expand**: the bottom of the panel displays a selection menu relative to eventual *[[#Categorical bed]]* files loaded by the user. In this field options will be available in the case when categorical bed files are loaded. By selecting one or more of the available file names from this menu, the user will select to expand the view of the categories belonging to the corresponding track in the central plot. Categories expansion can be relevant when genomic ranges annotated to different categories overlap. In this case the can be plotted on different lines and separated through the categories expansion option. ^d7d54e

![[expand_categories.jpg | center]]

- **Expand transcripts**: the lowermost option available from the right navigation panel allows to take action on the genome annotation track relative to the active reference genome. In the default visualization *Gene tracks* are collapsed. By checking the *Expand transcript* box genes annotations relative to the visualize genomic range will be expanded to visualize all the annotated transcripts.

![[expand_transcript.jpg | center]]

## Usage

The previous sections already describe all the main functionalities of the **Genomic viewer**. In this section it will be described more in details the **usage of the tool** and the **different options** that are tunable by the user will be covered in a more **practical aspect**.

### Setting up the input datasets

The first thing to do before starting the **Genomic viewer** app is to fill in the [[#Configuration file]] with all the required information about the local *path to the files*, the *files pattern* and *user-defined name*s to be employed by the app. Remember that by default **Genomic viewer** works on the **[GRCh38 (hg38)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001405.26/)** reference genome, so the genomic annotation files for this reference genome are already available and it is sufficient to indicate their path in the [[#Configuration file]]. In case a different reference genome will be used, the annotation files must be prepared by the user as described in the [[#Reference genome]] section. 
### Selecting the genomic region to visualize

Once the [[#Configuration file]] is ready the app can be started. It will automatically show a test genomic range (chr1: 28000000-28500000), the corresponding plot, data and stats will however only be displayed only when the user clicks the *[[#^dbc4a3|GO button]]*. If the user wants to visualize its own genomic region to visualize there are different options described below.

#### Manual entering of coordinates

The most basic way to insert specific coordinates to be visualized is by manually typing in the *chromosome name*, *start* and *end* coordinate. This is feasible form the [[#^57c39c|left sidebar]]. The [[#Plot, Data and Stats tab]] will update with the new coordinates only upon clicking on the *[[#^dbc4a3|GO button]]*. Note that in the *Choose chromosome* field just the number or letter corresponding to the intended chromosome must be typed without being preceded by the *'chr'* string (e.g. *1* and not *chr1* or *X* and not *chrX*).

![[manual_entering_coord.jpg]]
#### Chromosome hover

In case the user wants to visualize an entire chromosome the [[#^d610b2|right navigation bar]] reports an interactive plot from which the user can mouse hover and click on the desired chromosome. The coordinates displayed in the [[#^57c39c|left sidebar]] will update according to the start and end coordinate of the selected chromosome. The [[#Plot, Data and Stats tab]] will be updated only upon clicking the *[[#^dbc4a3|GO button]]*. 
#### Search by gene

In case the user wants to visualize a specific gene, it can be queried by mean of the ***gene name***. Gene names can be entered from the *Search by gene* bar in the [[#^d610b2|right navigation bar]]. When the user starts to type the gene name a drop down menu will appear with the possible options matching the typed string. After selecting or typing the complete gene name, the [[#Plot, Data and Stats tab]] will update upon clicking the *[[#^dbc4a3|GO button]]*. 

#### Zoom-in and out

Another way to select a specific genomic window to be visualized is by starting from a position and next gradually **[[#^af61fe|zooming-in and out]]** to adjust the focus on specific features of interest. This is feasible from the bottom part of the central **Plot** panel. 

![[zoom_bar_wSections.jpg|center]]

The **zoom bar** offers different modes for zooming-in and out as illustrated in the figure above:
- **Static plot zoom**: The '+', '-' and 'RESET' buttons in the bottom right corner of the genomic view plot allows to zoom-in and out the plot without changing the visualized genomic coordinates. The resolution of the plot will not change by zooming-in since it is a **vectorial image**. The 'RESET' button allows to restore the initial plot size. note that this type of zoom is just for dynamic visualization within the app and will not be applied on the **[[#Downloading plots and data|saved plot]]**.

- **Drag an drop bar**: below the static zoom button there is a draggable bar consisting in an orange rectangle, that matches the plotted genomic range, and grey flanking representing the ***25% extensions*** of the visualized range. The numbers below the bar report the coordinates in bp. By mouse drag-and-drop in the orange rectangle the user can zoom-in in the visualized genomic area, while by mouse drag-and-drop in the grey area the user can either zoom-out enlarging the actual genomic range or zoom-in in the flanking range. The maximum allowed zoom-in is **500 bp**, further zoom will not be allowed. Zooming by drag-and-drop is **limited to the selected chromosome coordinates**. The coordinates of the zoomed region will be automatically displayed in the [[#^57c39c|left sidebar]], but the [[#Plot, Data and Stats tab]] will be updated just upon clicking the *[[#^dbc4a3|GO button]]*.

- **Proportional zoom buttons**: the lowermost zoom option in the **Zoom bar** allows the user to **proportionally enlarge or restrict** the visualized genomic range, by always keeping the initial region in the middle of the plotted area. Different buttons are available to zoom-in or out by **1x**, **5x** or **10x**. The user can click once or several time on each button, at every click the coordinates displayed in the [[#^57c39c|left sidebar]] will update. The [[#Plot, Data and Stats tab]] will only reload once the user clicks the [[#^dbc4a3|GO button]]. The maximum allowed zoom-in is **500 bp**, further zoom will not be allowed. Zooming by drag-and-drop is **limited to the selected chromosome coordinates**.
### Plot, Data and Stats tab

The main functionalities of the **Genomic viewer** can be accessed through the three tabs in the [[#^af61fe|central panel]]. These allow respectively to visualize the genomic and annotation tracks loaded by the user through the [[#Configuration file]] with few options to adapt the output, to display and download the raw data corresponding to a user-selected genomic range, and to obtain an overview of some feature relative to the different tracks type.
#### Genomic view plot of the selected genomic range

The principal output of the app is the **genomic view plot**. This will be generated using the track files selected by the user in the [[#Configuration file]]. The tracks will be plotted after [[#Selecting the genomic region to visualize]] and can be updated at any time.  
Depending on the type of track and the wideness of the selected genomic region, the tool behaves differently to improve the image readability and computation speed. It follows a description of all the single tracks that can be displayed, if available which are the options that the user has to modify their visualization, and how the tool calculates the output depending on the size of the genomic range to be visualized.
##### 3D contacts Heatmap Matrix

File of the *.hic* format are used to plot [[#HiC and 3D contact matrices]]. There are several methods for plotting the matrices, in the **Genomic viewer** triangular matrices are plotted as *triangular matrices*. This type of data and consequently the resulting plot can be very heavy, therefore different resolutions can be set to obtain a compromise between the detailed to be visualized form the data and the computational/output expensiveness. To this aim the **Genomic viewer** automatically applies different data resolutions based on the size of the genomic regions that is requested to plot. In particular:
- for genomic ranges larger than 5 Mbp the binning resolution will be of 500 kbp;
- for genomic ranges > 100 kbp and ≤ 5 Mbp the binning resolution will be of 100 kbp;
- for genomic ranges > 25 kbp and ≤ 100 kbp the binning resolution will be of 25 kbp;
- for genomic ranges ≥ 15 kbp and ≤ 25 kbp the binning resolution will be of 15 kbp (this must be compatible with the loaded data resolution, otherwise will not be plotted);
- for genomic ranges < 15 kbp the 3D contact matrix will not be plotted since it approaches the minimal resolution allowed by the data and will not have a significant biological meaning.

The image below shows some examples of HiC heatmaps plotted at different resolutions based on the genomic range.

![[3D_matrix_resolutions.jpg|center]]

##### bigWig profile and heatmap tracks

File of the *.bigwig* format are used to plot [[#ChIP-seq, ATAC-seq, RNA-seq or any other bigWig| ChIP-seq, ATAC-seq, RNA-seq and several other NGS datasets]]. The most common way in which *bigwig* files are plotted is as signal intensity ***profile plots***, however in some cases it can be useful to plot them as ***heatmaps***. The **Genomic viewer** allows both [[#^ab5d51|visualization modes]], plus it allows to plot the same track simultaneously as *profile* or *heatmap*. *Bigwig* files are thought for data visualization and contain a score that is proportional to the signal intensity for defined genomic bins. This score information is either plot as signal profile (histogram-like, built-in function of **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotSignal.html)**) or transformed in a color-scale employed to generate a heatmap (**[plotgardener ranges](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html)**). 
Like the [[#3D contacts Heatmap Matrix]] plots, also the *bigwig* files normally bins genomic windows as a compromise between resolution and computational expenses. To speed up the dynamic visualization of the tracks in the **Genomic viewer** without loosing information, both ***profile plots*** and ***heatmaps*** generated from *bigwig* files are binned depending on the size of the genomic range selected by the user:
- for genomic ranges ≥ 200 Mbp the binning resolution will be of 1 Mbp;
- for genomic ranges ≥ 50 Mbp and < 200 Mbp the binning resolution will be of 50 kbp;
- for genomic ranges ≥ 5 Mbp and < 50 Mbp the binning resolution will be of 500 kbp;
- for genomic ranges ≥ 100 kbp and < 5 Mbp the binning resolution will be of 5 kbp;
- for  genomic ranges < 100 kbp no binning is applied, preserving the resolution of the original input file.

The image below shows some examples of *profile* plots and *heatmaps* from the same input *bigwig* file, plotted at different resolutions based on the genomic range.

![[bigwig_binning.jpg|center]]

When multiple *bigwig* files are loaded and must be compared, it is good practice to uniform the y-scale for all samples. In the **Genomic viewer** the y-scale for bigwigs is automatically auto-scaled based on the maximal *y* value of the most intense sample, every time the selected genomic range is updated. When multiple *bigwig* files are loaded a different color is automatically applied to every sample, when plotted in the *profile mode*
##### Peaks bed file tracks

[[#Peaks bed|Peak]] files are normally stored in the *.bed* format. These files are plotted as ranges by exploiting the corresponding built-in function from **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html)**. When multiple *peaks .bed* files are loaded by the user a different color is automatically applied to every sample. There is no customization option for this type of track and no binning is normally necessary.
An example of how peak file track appears in the **Genomic viewer** is reported in the figure below:

![[peak_bed_track.jpg|center]]
##### Categorical bed file tracks

In addition to *peaks ranges* *.bed* files can also be used to mark genomic regions that belong to specific categories, which can be annotated with some external tool or database, or defined by he user. The **Genomic viewer** allows to load [[#Categorical bed|categorical .bed]] files and plot them by exploiting the same built-in function from **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html)** that is used for standard [[#Peaks bed]]. 
In **Genomic viewer**, every category that is found in the [[#Categorical bed]] file is associated to a different color and represented in a legend beside that corresponding track in the plot. Since it can happen that the genomic ranges belonging to different categories overlap, or that a same genomic range belongs to two categories, **Genomic viewer** has the possibility to **[[#^d7d54e|expand or collapse]]** the categories.
An example of *collapsed* and *expanded* categorical bed tracks is reported in the figure below:

![[collapsed_expanded_categories.jpg|center]]
##### 3D contact arches 

In addition to contact matrices and heatmap, 3D contacts can also be represented as ***arches*** connecting the 2D genomic positions that are touching. This type of representation is stored in [[#3D contacts arches bedpe|bedpe files]] and is plotted in **Genomic viewer** through a dedicated **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotPairsArches.html)** built-in function. Some [[#3D contacts arches bedpe|bedpe files]] also have a *score* column containing a value that is proportional to the *strength/likelihood* of the contact. In this latter case the corresponding arch thickness will be proportional to the contact score.
There is no customization option for this type of track and no binning is normally necessary.
An example of how *3D contact arches bedpe* file track appears in the **Genomic viewer** is reported in the figure below:

![[3D_contact_arches.jpg|center]]
##### GWAS Manhattan track

**[[#GWAS summary statistics]]** files can be exploited to generate **[[#^18d054|Manhattan plots]]** for the identification of trait-associated SNPs. Once the **[[#GWAS summary statistics]]** file has been correctly arranges by the user, the **[[#^18d054|Manhattan plots]]** are generated in the **Genomic viewer** through the dedicated **[plotgardener](https://phanstiellab.github.io/plotgardener/reference/plotManhattan.html)** built-in function. In this plot every SNP is represented by a dot, which color is representative of the p-value of its association with specific traits, depending on the dataset. A **color-scale legend** is reported beside to the track plot and a dashed line indicate the *significance threshold*.
There is no customization option for this type of track and no binning is normally necessary, however an overview of the visualized chromosome with a zoom-in on the selcted region and most significant SNPs label are reported in the [[#^95ac88|Stats tab]]. 
An example of how  **[[#^18d054|Manhattan plots]]** track appears in the **Genomic viewer** is reported in the figure below:

![[Manhattan_plot_track.jpg|center]]
##### Genes annotation track

describe the behavior with the different types of tracks, i.e. gene tracks are plotted as density plots when regions larger than 10Mb are displayed to improve computing time and image readability. 

descrivere anche le opzioni che si hanno per modificare le tracce e.g. categories expand and expand transcripts.
quindi descrivere qui anche la sezione con le annotazioni genomiche. 

Aggiungere i riferimenti alle analisi 

#### Visualize raw data for the selected genomic range

#### Visualize basic statistics analysis for the loaded data

### Downloading plots and data

#### Download of the genomic view plot

#### Download of raw data of the plotted genomic range

#### Saving basic statistics plots

### R session info
