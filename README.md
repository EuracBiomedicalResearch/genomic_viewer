
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

The following section will describe how 
Configuration file

## Output results


## Structure of the Genomic viewer interface
### Main panel

## Usage

### Selecting the genomic region to visualize
#### Chromosome hover
#### Search by gene

#### Zoom-in and out

### Downloading plots and data
