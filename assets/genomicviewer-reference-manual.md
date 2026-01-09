---
output:
  html_document: default
  pdf_document: default
---

# Genomic Viewer Reference Manual
<div align="center">
<img src="GV_scheme.png" width="60%"/>
</div>

**Version:** 1.0.0
**Description:** Genomic Viewer is a cross-platform application for visualizing
and analyzing genomic data hosted in a Docker container.

------------------------------------------------------------------------

## Table of Contents

<details open>
<summary>&nbsp;</summary>

1.  [Configuration](#configuration)
2.  [File Formats](#file-formats)
3.  [Features and Usage](#features-and-usage)
4.  [Tutorial](#tutorial)
5.  [Getting Help](#help)
6.  [References and Links](#references-links)

</details>

------------------------------------------------------------------------

## Configuration

<details open>
<summary>&nbsp;</summary>

During [***Genomic Viewer***
installation](https://github.com/EuracBiomedicalResearch/genomic_viewer/blob/docker-genomicviewer/README.md#installation)
a local directory is specified which will be used by the app for accessing data
to be visualized. In that folder the installer will create by default a `data`
directory containing the *tutorial example data* and a *configuration file*.

The `GenomicViewer_config.yml` file is the only configurable object that is
essential for starting a ***Genomic Viewer*** session. This file specified
which and how data are visualized. The advantages of this approach are
summarized as follows:

- Keep all files organized in a common parent directory.
- Avoid use of hard-coded absolute paths.
- Facilitate exchange of data between collaborators.

Here are some points to consider when modifying the configuration file:

<!-- This is not clear. I also don't see why this level of detail should be
     among the first lines explaining the config file.
     XXX revise
-->
- It is not necessary to change the `data.dir` field unless you created a common
  sub-directory to `data` with all the files to be uploaded;

- The configuration file reports a single section relative to each accepted
  [File Format](#file-formats);

- Each section requires three fields: `dir` for the specific sub-directory, if
  present; `ext` for the file extension or shortest common substring in file
  names of the same type; and `names` which is an array of quoted string to be
  used as labels for the input data.

<!-- specify which type of reg ex can be used. There are multiple types. E.g.
 POSIX, Perl, extended. If you really want to link to a site, choose a serious
 one.
-->

<!-- you are explaining something that has not been introduced before. This
 is confusing. I have no clue what name labels are. Introduce things properly
 before talking about them.

 Ok, after a while of looking at the config file and reading this manual,
 here are the things I am interested in with respect to the config file (see
 also comments directly in the config file.)

 - I think it's better to show first the config file and then go through
   it, line by line, listing all the details for each entry.
 - What is the general syntax of this file? I am sure you are using a parser
   for it.
 - How in general is error handling implemented? The config file opens the
   gate to hell. E.g. incorrectly spelled files/directory names, incorrect
   tokens such as "bg.dir" instead of "bw.dir", etc.
 - Is the order of entries important? bw.dir before bw.ext for example?
 - The names .ext are a bit confusing. These are file names or regular
   expressions, true? .ext let's everybody think of extensions. ".txt" is an
   extension...
 - So if we e.g. don't have bigwig data to display, what do we do? According
   to the config file and my knowledge so far, we would need to specify
   [""] or "  " (two spaces, really??) in the bw.names tag? I guess I am
   wrong, so this needs a better explanation. In fact, at the moment, I cannot
   see how the bigwig file is found. Overall, we need a clear description how
   files are searched. It would be good to have regexps in the example config
   file, at least used once to show how they work.
 - What happens, if we enter bw.dir twice? Will both directories be searched
   or the last occurrence?
 - The assignment of bw.names to tracks inside the respective files is not at
   all user friendly and very prone to errors. How should the user know what
   is the alphabetical order of all items? I would prefer something more
   explicit.
-->

**Note:** In the `ext` fields you can use regular expressions as input, use only
the file extension as parameter or type the entire file name for safety.  When
loading several files of the same format through extension or regular expression
please remember that files are always read in alphabetical order, therefore their
*name labels* must follow the file order to be correctly assigend.  In the
presence of multiple subfolders with data of the same file format, the `dir`
field also accepts an array following the same rules of `name` labels arrays.
When loading **.bam** files it is recommended to use the regular expression `$`
to specify the end of the file extension (like this `.bam$`), this avoids to
erroneously try to load the associated *.bai* files.
<!-- Well, the last paragraph needs much more examples and details. Up to here
it is not even clear how reg.exps are applied. -->

- ***Genomic Viewer*** only reads one configuration file termed
  `GenomicViewer_config.yml`. In order to handle multiple different sessions,
  you need to keep copies of that file in some other location or under a
  different name.

- When one filed is empty because you do not want to enter a subdirectory,
  assign a name or you just do not have a specific file format to load, you must
  enter a **two whitespaces** empty string "  " or vector '[""]' to prevent
  unwanted behaviors
  <!-- where do we need to enter that? *.dir, *.ext, *.names? Why not comment
   out respective section? -->

- The last field in the configuration file refers to a custom BED file with a
  saved preset of coordinateds of interest. This file con be substituted or
  dynamically modified during every working session.
  <!-- what is the file format. In case you explain it later, I don't know it
  at the moment, because I am reading the manual the first time. Like anybody
  else. So refer the reader to the appropriate section(s) where this is
  addressed -->

- Most of these instructions and field description are also summarized in the
  configuration file itself so you do not need to refer to the manual every
  time.
  <!-- good point, but for this the config file needs to be very descriptive.
  We have not reached this point yet. -->

An example of the configuration file is reported below:
<!-- Obviously, insert the final version of the config file here -->
```
---

default:

    # Set here the parameters related to the input files path and extensions

  # Data directory
  data.dir: "/data/"

  # bigWig directory and files final pattern or complete name (can correspond to one or more tracks), ordered file name to visualize. If empty type "  " or [""] in names.
  bw.dir: "GSE212908_RAW_ATAC_bigwig"
  bw.ext: "treat_pileup_chr5.bw"
  bw.names: ["Kidney cortex 12", "Kidney cortex 15"] # Comma separated, "quoted" names

  # BEDpe directory and files final pattern, ordered file name to visualize. If empty type "  " or [""] in names.
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

  # file with selected genomic regions to be imported (BED format: chr, start end, name. No header). If empty type "  " or [""] in names.
  reg.dir: ""
  reg.file: "Example_region_table.bed"

```

Please note that the configuration file has a unique hard-coded name,
`GenomicViewer_config.yml`. When working on multiple sessions simultaneously,
replace this file with the desired copy you keep in a different location or/and
under a different name.

</details>

------------------------------------------------------------------------

## File Formats

The following section will describe the file formats that can be imported in
**Genomic viewer**, mentioning if there are specific requirements and for which
track plot they are useful.

<details open>
<summary>bigwig</summary>

### bigWig

Most of the 2D NGS datasets are stored as bigWig file format, which represents
values along the genome, such as read coverage, signal intensity, or enrichment
scores. BigWig files are indexed binary files allowing fast access of selected
portions.

The most common data types that can be loaded through a bigWig file are
ChIP-seq, CUT&Tag, ATAC-seq, RNA-seq and any genome-wide quantitative signal
dataset.

For more details on the bigWig track format see the [UCSC web
portal](https://genome.ucsc.edu/goldenpath/help/bigWig.html).

</details>

<div>
<details open>
<summary>BED</summary>

### BED

[BED files](https://www.ensembl.org/info/website/upload/bed.html) are used to
store genomic ranges annotations, which can be for instance ChIP-seq or
ATAC-seq peaks. BED files can contain a variable number of columns with
mandatory and optional information. For the purposes of ***Genomic Viewer***
only three fields are strictly necessary in this tab-separated file:
**chromosome name**, **start**, **end**.  For example:
<!-- does it need to be "chr1" or is "1" also good? Does this depend on the
file content? Explain. -->

```
chr1  213941196  213942363
chr1  213942363  213943530
chr1  213943530  213944697
```

Make sure that your file does not have a header with column names (like `chr`,
`start`, `end`, or a comment `#`) to ensure proper reading of the file.
Additional columns are allowed, those will be displayed in the *Data*
navigation tab, but are ignored for plotting.

</details>
</div>

<div>
<details open>
<summary>Categorical BED</summary>

### Categorical BED

In addition to the standard BED file, ***Genomic Viewer*** also accepts
categorical BED files which are structured like the standard BED but have an
additional required column, assigning the corresponding genomic range to a
user-defined category. In addition, categorical BED columns are named with a
header, as in the example below.  Categorical BED can be used for example to
classify peaks or functional genomic elements. For instance, several
functional element coordinates (like the ones provided for in the
[tutorial](#tutorial)) can be downloaded from [UCSC Table
Browser](https://genome.ucsc.edu/cgi-bin/hgTables).  The resulting file
looks like this:

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

Note that the same genomic range can belong to two different categories, in
this case the entry must be repeated two times, with a single value in the
category field.  Additional columns will be ignored for plotting but are kept
in the *Data* navigation tab.

*Categorical BED* format is highly flexible, allowing many different types of
data to be organized and visualized.

</details>
</div>

<div>
<details open>
<summary>HiC</summary>

### HiC

3D contacts files, like HiC, stored in [HiC file
format](https://genome.ucsc.edu/goldenpath/help/hic.html).  This is a binary
format allowing fast access to contact matrices and is used for displaying
chromatin conformation data in our browser. HiC files are generally large files
and can store the information at different resolutions and normalizations.  It
is suggested to include a column with *KR normalization*.  More on HiC
*normalization methods* can be found in the [*Normalization of Hi-C
Maps*](https://gcmapexplorer.readthedocs.io/en/latest/cmapNormalization.html)
article. Based on their availability in the source data file, ***Genomic
Viewer*** reads `.hic` files at different resolutions depending on the size
of the requested genomic window to plot.

</details>


<div>
<details open>
<summary>BEDPE</summary>

### BEDPE

3D contacts can also be stored as arches connecting two distal genomic regions.
This type of information is stored in the [BEDPE file
format](https://bedtools.readthedocs.io/en/latest/content/general-usage.html#bedpe-format).
Normally BEDPE files are 6 columns files with *chr*, *start*, *end* fields of
the two anchor and bait regions, however optional columns can be added. In the
latter case column 7 contains an ID, the 8th column is a number representing
the score and the 9th column represents the DNA strand. A column header is
optional and will not affect the output.

An example of the minimal BEDPE file structure is reported below:

```
chrA  startA  endA  chrB  startB  endB
chr5	74050000	74060000	chr5	74640000	74650000
chr5	75350000	75360000	chr5	75670000	75680000
chr5	75740000	75750000	chr5	76150000	76160000
chr5	77560000	77570000	chr5	77960000	77970000
```

</details>
</div>


<div>
<details open>
<summary>GWAS</summary>

### GWAS

Genome Wide Association Studies (GWAS) datasets are stored in a dedicated file
format. The [GWAS Catalog](https://www.ebi.ac.uk/gwas/) database
storing this type of data has recently updated and uniformed the structure of
the deposited summary statistics file format.  These are normally stored as
gzipped .tsv files since contain huge amount of data.  To generate a
Manhattan plot with ***Genomic Viewer*** there are four required fields,
which contain information about **chromosome name**, **position**, **p-value**
and **SNP id**.  These fields must be tab-separated and named with a header as
in the example below:

```
chrom   pos         p       snp
chr1	162766673	3.1e-01	rs1000050
chr1	157285606	1.1e-02	rs1000073
chr1	94701276	4.5e-01	rs1000075
chr1	66392232	3.3e-01	rs1000085
chr1	62967045	5.3e-01	rs1000127
chr1	205536349	6.0e-01	rs1000312
```

Any number of additional fields can be optionally added with no restriction in
their name. All of the minimal required fields are always available in [GWAS
Catalog](https://www.ebi.ac.uk/gwas/) summary statistics files. It is however
recommended to check the columns headers to match the ***Genomic Viewer***
requirements. If only plots will be generated, in order to save space and
increase loading speed, we recommend to keep only the four required columns.

</details>


<div>
<details open>
<summary>bam</summary>

### BAM

The BAM file format is a binary file format used to store the results of
sequencing reads alignments. To allow graphical tools to access this type of
data the file must be indexed, therefor every `.bam` file must always be
associated to a corresponding `.bam.bai` file. For a more extensive description
of BAM files we refer to the [BAM Track
Format](https://genome.ucsc.edu/goldenpath/help/bam.html) of the UCSC web
portal.  Sometimes publicly deposited BAM files are not indexed, in order to
index a bam file it is recommended to use [*Samtools
index*](https://www.htslib.org/doc/samtools-index.html) function.  BAM files
tend to be large files.

</details>
</div>
</div>
</div>

------------------------------------------------------------------------

## Features and Usage

In the following section the user will find a detailed description of the main
functions that are available from ***Genomic Viewer*** interface.

<div>
<details open>
<summary>Interface organization</summary>

### Interface organization

The user interface of ***Genomic Viewer*** is split into three main areas: left
and right sidebar and the central window.

<img src="GV_main_window_sections.png"
     alt="GV overview of the interface with sections"
     width="80%">

**Left sidebar**

| Section/Button     | Function                                              |
|--------------------|-------------------------------------------------------|
| Reference genome   | Select a reference genome form list.                  |
| Insert coordinates | Choose chromosome to visualize from dropdown menu and|
|                    | enter start and end coordinates.                      |
| Load coordinates   | Load a BED format file with a list of saved genomic   |
|                    | coordinates. If present, the file specified in the    |
|                    | configuration file will be loaded as default.         |
| Go button          | Generate plot according to the selected options.      |
| Save button        | Export plot choosing among different formats:         |
|                    | SVG, PDF, PNG, JPG.                                   |


**Right sidebar**

| Section/Button     | Function                                              |
|--------------------|-------------------------------------------------------|
| Choose chromosome  | Select a chromosome to plot by hovering over the plot |
|                    | and clicking.                                         |
| Search by gene     | Search the genomic coordinates of a gene              |
| bigWig plot mode   | Choose if plotting bigWig tracks in profile or heatmap|
|                    | mode. Both plots can also be generated simultaneously.|
| Autoscale settings | Define grouping rule for autoscaling bigWig tracks.   |
| Expand category    | Expand tracks loaded from categorical BED files to    |
|                    | avoid categories overlap.                             |
| Expand transcripts | Alternative to gene label track, plots transcript     |
|                    | isoforms individually.                                |
| Chromosome ideogram| If checked, shows the chromosome ideogram in the plot.|

**Central window**

| Section/Button     | Function                                              |
|--------------------|-------------------------------------------------------|
| Plot, Data, Stats  | Click to access the corresponding navigation tab and  |
|                    | related functions.                                    |
| Zoom section       | Increase/decrease genomic range in the plot.          |

</details>
</div>

<div>
<details open>
<summary>Reference genome</summary>

### Reference Genome

Choosing a reference genome is the first essential step to address before
generating any plot. The reference genome provides the desired coordinates to
ensure that the values you enter in the GUI match the data. The reference
genome can be selected from a built-in list available form a dropdown menu at
the top of the left sidebar. The reference genome and all user-supplied data
files (via the the [configuration file](#configuration)) have to match. At
***Genomic Viewer*** startup the human hg19 (GRCh19) version of the reference
genome is loaded by default.

<img src="GV_ref_genome.png" alt="GV select reference genome menu" width="25%">

Changing the selected working reference genome will affect the list of
chromosomes in the *Insert coordinates* panel, the chromosome hover plot, the
list of available gene names and the gene annotation labels in the main plot
output.

</details>
</div>

<div>
<details open>
<summary>Navigation</summary>

### Navigation

***Genomic Viewer*** offers several options to navigate across the genome.
Their usage is described in the following section.

#### Insert coordinates

One possibility to tell ***Genomic Viewer*** which coordinates you want to plot
is through the *Insert coordinates* panel.  This panel allows to manually
insert coordinates to be plotted by selecting the chromosome name from a
dropdown menu, and entering the start and end coordinates in the numeric entry
fields available from the same panel followed by hitting the *Go* button.

<img src="GV_insert_coordinates.png"
     alt="GV insert coordinates panel for genome navigation"
     width="25%">

#### Load coordinates

The user can navigate across a list of previously saved coordinates by
specifying a region table BED file to be uploaded through the [configuration
file](#configuration) or by accessing local files in a running ***Genomic
Viewer*** session. The provided coordinates list file must be structured as a
BED file with a minimum of three tab separated columns corresponding to:
chromosome, start, and end. It is recommended to have a fourth column with a an
ID for the corresponding genomic region. Column headers should be avoided.

An example of region table BED file is reported below:

```
chr5	177365507	177412577	SLC34A1
chr5	177372928	177499184	SLC34A1_zoomOut
```

Once the region file is uploaded, the coordinates become available in the
**Select from menu** dropdown list.

<img src="GV_load_coordinates_menu.png"
     alt="GV load coordinates allows to choose coordinates from a saved list"
     width="30%">

A custom region table list can be created by either generating a new one or by
modifying a previously uploaded table. The *Add* and *Remove* buttons below the
selection dropdown menu allow to access these options. In particular, to add a
new entry to the an existing list or to create a new one after clicking the
*Add* button a pop-up window will appear reporting the selected coordinates and
allowing the user to assign a name to the region. By clicking *Ok* the entry
will be added to the list.

<img src="GV_load_coordinates_add.png"
     alt="GV load coordinates panel for adding new coordinates to list"
     width="35%">

Similarly, if you want to remove a coordinate from the uploaded list, you can
select the entry form the dropdown list and next click the *Remove* button.
The new custom coordinates list can also be exported for later re-use.

To restore the initial setting of the *Load coordinates* panel it is sufficient
to click the *Reset* button at the panel's bottom.

#### Choose chromosome

To visualize a whole chromosome or perform an analysis on it, at the top of the
right sidebar there is a schematized graphics of the chromosomes structures
corresponding to the selected reference genome. The plot will update every time
the user selects a different reference genome.  The *Choose chromosome* plot is
an interactive plot supporting mouse hovering. A label with the chromosome id
of the hovered region will appear below the graph. Upon clicking the
corresponding coordinates are passed to ***Genomic Viewer*** and the genomic
plot or desired analysis can be generated by pressing the *Go* button.

<img src="GV_choose_chrom.png" alt="GV choose chromosome hover and click plot" width="30%">

#### Search by gene

If a user is interested in visualizing or analyzing the genomic region
corresponding to a specific gene, the easiest way is to retrieve its
coordinates from the *Search by gene* menu. To search for a gene of interest in
the currently selected reference genome, you can start typing the gene name in
the menu and a list with the matching entries will be displayed below. Once
the gene of interest appears you can click on it and the tool will
automatically load its coordinates. Note that changing the reference genome
after selecting a gene the coordinates will not update automatically, but
you have to search again for the gene in the menu.
<!-- Ideally, change of the reference genome should clear the Load coordinates
 panel. To be implemented! -->

<img src="GV_search_gene.png" alt="GV search by gene function" width="30%">

To trigger the generation of the plot or run an analysis, after choosing the
gene of interest one must click the *Go* button.

#### Zoom

The zoom panel located at the bottom of the plot navigation panel in the
central window offers an alternative way for genome navigation. This is
especially useful when investigate the flanking regions of a selected genomic
position or when narrowing down the region of interest. See also the
[Tutorial](#tutorial).

There are two ways for using the zoom panel for navigation:

- **Drag and drop bar**: above the zoom buttons there is a draggable bar
  consisting of an orange rectangle that matches the plotted genomic range and
  a grey flanking region. The scale below the bar represents base pairs.
  Selecting a rectangle within the orange area results in a zoom in, while
  selecting in the grey area a zoom out will be done. The maximum allowed
  zoom-in is 500 bp. The coordinates of the zoomed region will be automatically
  updated in the Insert coordinates panel, but the plot has to be redone
  manually by hitting the *Go* button. This way, multiple zooms can be
  combined.

- **Proportional zoom buttons**: Below the position bar there are buttons to
  zoom in and out 2, 5, or 10 times, respectively. The initially shown area
  will remain the center of zoomed region. Again, hitting the *Go* button will
  replot the newly selected genomic region.

<img src="GV_zoom_bar.png" alt="GV navigation through zoom bar" width="80%">

</details>
</div>


### Genomic View Plot

The main graphical output of the app is the genomic view plot, accessed through
the *Plot* navigation tab which is shown by default at startup. The plot is
generated using the track files specified by the user in the [configuration
file](#configuration). ***Genomic Viewer*** handles the genomic data track's
formats using specific functions and graphical parameters which are managed
through custom functions utilizing the
[`plotgardener`](https://phanstiellab.github.io/plotgardener/index.html)[[1]](#ref1)
R package.

<div>
<details open>
<summary>Track specific features</summary>

#### Track-specific Features

Tracks are visualized in the central window in a fix order. In the following
sections, we describe each of them in that order.

##### HiC 3D contact matrix

Files formatted as [HiC](#HiC) are used to plot HiC and 3D contact matrices.
***Genomic Viewer*** represents this type of data as triangular matrices.
Contact scores that are stored in the input file are displayed as a heatmap and
will be scaled in the range of 1-100 to maximize their visual evaluation. The
corresponding scale bar is always reported beside the plot.
<!-- Do not understand what the "range of 1-100" means. Resolution? Specify. -->

These files can be quite large and for performance reasons, ***Genomic
Viewer*** automatically sets different data resolutions based on the size of
the genomic regions that is requested to plot.

In particular:

- for genomic ranges larger than 5 Mbp the binning resolution is 500 Kbp;

- for genomic ranges > 100 kbp and ≤ 5 Mbp the binning resolution is 100 Kbp;

- for genomic ranges > 25 kbp and ≤ 100 kbp the binning resolution is 25 Kbp;

- for genomic ranges ≥ 15 kbp and ≤ 25 kbp the binning resolution is 15 Kbp
  (this must be compatible with the input data resolution, otherwise will not
  be plotted);

- for genomic ranges < 15 kbp the 3D contact matrix will not be plotted since
  it approaches the minimal resolution allowed by the data and will not have a
  significant biological meaning.

The image below shows some examples of HiC heatmaps plotted at different
resolutions according to the genomic range.

<img src="GV_hic.png"
     alt="GV hic tringular matrix at different resolutions"
     width="90%">

##### BigWig profile and heatmap

Files formatted as [bigWig](#bigwig) are used to plot any coverage or signal
score data like ChIP-seq, ATAC-seq, RNA-seq and many others. The most common
way in which bigWig files are plotted is as signal intensity profile plots,
however in some cases it can be useful to plot them as heatmaps.  **Genomic
viewer** allows both visualization modes, plus it allows to plot the same track
simultaneously as profile or heatmap.

This score information stored in bigWig files is binned. This information is
used to generate either the standard histogram-like profile plots, making use
of the `plotgardener` function
[`plotSignal()`](https://phanstiellab.github.io/plotgardener/reference/plotSignal.html),
or is color-coded in a heatmap through the `plotgardener` function
[`plotRanges()`](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html).

The appropriate plot is chosen in the *Select bigwig plot mode* menu in the
right sidebar. The plot is recreated automatically afterwards.
<!-- why then not also replot when selecting a gene from Search by gene? This
 I have already suggested. -->

<img src="GV_bigwig_mode.png"
     alt="GV bigwig plot mode dropdown menu"
     width="30%">

Like the 3D contact matrix plots, also the bigWig files can be plotted using a
different bin size as a compromise between resolution and computational
expenses.

To optimize visualization performance without loosing information, both profile
plots and heatmaps are independently binned based on the size of the genomic
range selected by the user:

- for genomic ranges ≥ 200 Mbp the binning resolution is of 1 Mbp;

- for genomic ranges ≥ 50 Mbp and < 200 Mbp the binning resolution is of 500
  kbp;

- for genomic ranges ≥ 5 Mbp and < 50 Mbp the binning resolution is of 50 kbp;

- for genomic ranges ≥ 100 kbp and < 5 Mbp the binning resolution is of 5 kbp;

- for  genomic ranges < 100 kbp no binning is applied, preserving the
  resolution of the original input file.

The image below shows some examples of profile plots and heatmaps from the
same input bigWig file, plotted at different resolutions according to the
genomic range.

<img src="GV_bigwig.png"
     alt="GV bigwig profile and heatmap plots at different resolutions"
     width="90%">

When multiple bigWig files are loaded and want to be compared, it is good
practice to keep the y-axis scale constant for all samples. However, different
sequencing techniques describe different types of data using the bigWig format.
For these reasons ***Genomic Viewer*** offers the possibility to choose y-axis
autoscaling by groups. By clicking the *Autoscale settings* button in the right
sidebar, a pop-up window will appear:

<img src="GV_autoscale_group.png"
     alt="GV popup window for bigwig autoscale group"
     width="45%">

Groups are created by clicking the *+ Add* button and selecting the
corresponding samples.  If no grouping is required, one can check the *Set
Individual Scale* box.

By default the y-scale for bigWig files is automatically auto-scaled based on
the maximal y value over all samples and is updated every time the selected
genomic range is changes. When multiple bigWig files are loaded a different
color is automatically applied to every track. When plotted in the profile
mode the color/score scalebar is displayed on the right of the plot.


##### BED files

The [BED](#BED) file format is commonly used to store information regarding
annotation of peaks or genomic regions of interest in datasets from ChIP-seq
and ATAC-seq experiments. BED files are plotted by ***Genomic Viewer*** using
the `plotgardener` function
[`plotRanges()`](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html).

When multiple BED files are loaded by the user a different color is
automatically applied to every sample.  There is no customization option for
this type of track and binning is normally not necessary. However, when the
plotted range is larger than 10 Mbp, peaks are displayed as density plots to
improve readability and reduce image size.

An example of a peak file track in ***Genomic Viewer*** is shown below:

<img src="GV_bed.png"
     alt="GV BED file track for different genomic ranges"
     width="80%">

##### BAM files

[BAM](#bam) files store information on individual sequencing reads obtained
after alignment against a reference genome.  In ***Genomic Viewer*** BAM data
are plotted using the same function as for BED files, such that the genomic
range covered by the reads is shown. The two formats are automatically detected
by ***Genomic Viewer*** and while BED files are plotted in collapsed way, the
BAM files are expanded to allow the visualization of individual reads. High
number of reads exceeding plotting space are marked with a `+` sign in the
upper-right part of the track plot.

An example of aligned reads is shown below:

<img src="GV_bam.png"
     alt="GV example of aligned reads visualized from bam file"
     width="80%">

BAM files inspection is not among the main purposes of ***Genomic Viewer***.
Since BAM files are often very large, data are plotted as default behavior only
for highly zoomed region as is also the default behavior of the majority of
genome browsers. For these reasons BAM files are not provided as example
data in the [**Tutorial**](#tutorial), either. Nevertheless, testing this
funcitonality can be done by retrieving the raw data used to generate the
above image from the link reported in the [**References and
links**](#references-and-links) section.


##### Categorical BED files

[Categorical BED](#categorical-bed) files can be used to mark genomic regions
that belong to specific categories, which can be annotated with external tools
or databases, such as user-defined data.  ***Genomic Viewer*** plots
categorical BED files through the `plotgardener` function
[`plotRanges()`](https://phanstiellab.github.io/plotgardener/reference/plotRanges.html).
Every category that is found in the input file is assigned a different color
listed in a legend displayed to the right of the corresponding track in the
plot. By default all the categories in the same track are plotted in one line,
however, sometimes the genomic ranges belonging to different categories may
overlap, or the same genomic range belongs to two categories. To address these
situations ***Genomic Viewer*** provides the possibility to expand the
categories through the *Expand categories* menu in the right sidebar. When
clicking in the menu all the tracks that are uploaded as categorical BED
files are displayed by their label name. The user can choose multiple
of them to be expanded, so that overlapping categories of the same track are
split on different lines.
<!-- The last sentences on displaying and splitting I don't understand at
all. Rewrite. -->

<img src="GV_expand_cat.png"
     alt="GV drop down menu to expand categories of categorical BED file"
     width="30%">

An example of *collapsed* and *expanded* categorical BED tracks is shown in the
figure below:

<img src="GV_cat_bed.png" i
     alt="GV view of categorical BED in collapsed or expanded mode"
     width="80%">

A `+` character displayed at the top-right of the track indicates that some
information is hidded due to space constraints.

##### 3D Contact Arches

In addition to contact matrices and heatmaps, 3D contacts can also be
represented as *arches* connecting the 2D genomic positions.  This type of
representation is stored in [BEDPE](#BEDPE) files and is plotted in ***Genomic
viewer*** through the dedicated `plotgardener` function
[`plotPairsArches()`](https://phanstiellab.github.io/plotgardener/reference/plotPairsArches.html).

There is no customization option for this type of track and binning is not
necessary.

An example of a 3D contact arches track is shown below:

<img src="GV_arches.png"
     alt="GV examples of 3D contact arches track"
     width="80%">

##### GWAS Manhattan

[GWAS summary statistics](#gwas) files are the basis for Manhattan plots.  They
are generated in ***Genomic Viewer*** through the dedicated `plotgardener`
function
[`plotManhattan()`](https://phanstiellab.github.io/plotgardener/reference/plotManhattan.html).
In this plot every SNP is represented by a dot colored by p-value.  The input
file, column `p` (representing the p-value) is automatically converted to
-log10(p-value) as reported on the y-axis scale. A dashed line indicates the
significance threshold and is by default set to 10<sup>-8</sup>.

This track cannot be customized.

An example of a Manhattan plot by ***Genomic Viewer*** is shown below:

<img src="GV_gwas_track.png"
     alt="GV examples of Manhattan plot obtained from GWAS data"
     width="80%">

</details>
</div>

<div>
<details open>
<summary>Additional Plot options and features</summary>

#### Additional Plot options and features

##### Image Static Zoom

The `+`, `-` and `RESET` buttons in the lower right corner of the genomic view
plot allow to zoom in and out of the plot without changing the visualized
genomic coordinates.  The graphical resolution of the plot will not change by
zooming in since it is a vectorial image. The `RESET` button allows to
restore the initial plot size. The zoomed image can be panned by click-dragging.
This type of zoom is not taken into account when exporting an image.

In addition the static zoom controller is disabled when the cumulative size of
the files to plot is greater than 2 GB and the selected range to plot larger
than 500 kbp. This is because under such a condition the visualized image is
not vectorial, but is a bitmap for performance reasons.

In any case it will always be possible to download the image in vectorial
resolution (SVG format) using the *Save* button.

<img src="GV_static_zoom.png" alt="GV static zoom controllers" width="80%">


#### Tracks arrangement

***Genomic Viewer*** is thought to be sufficiently flexible to allow the user
to modify the strictly necessary graphical parameters, but also to require the
minimal effort in generating a **publication quality image**.  For this reason
the final size of the plot is predefined and each track, depending on its
format and the total number of tracks to be plotted, is automatically scaled to
occupy a precise space in the final output.
<!-- what do you want to say by that? This is very convoluted... -->

Having the possibility to download the image in **.svg** vectorial format always
allows to modify graphical parameters that cannot be controlled from the
application interface.
<!-- What does this mean? -->

</details>
</div>

<div>
<details open>
<summary>Genome annotation</summary>

### Genome annotation

The lowermost part of the main plot output consists of different layers of gene
annotations. Gene annotation is available for all the reference genomes
supported by ***Genome Viewer***.

The representation of genes and genes structures is done with the
`plotgardener` function
[`plotGenes()`](https://phanstiellab.github.io/plotgardener/reference/plotGenes.html).
It allows representation of functional elements like promoters, introns and
exons.

By default genes that are encoded on the leading and lagging DNA strand are
divided into two lines, marked as `+` and `-`.  Genes encoded on leading strand
are shown in green while lagging strand genes are plotted in light blue.

On the right sidebar it is possible to expand transcripts. So instead of genes,
the separated transcript isoforms are displayed on multiple lines.

<img src="GV_expand_transcript.png" alt="GV checkbox to expand transcripts"
     width="25%">

The difference is shown here:

<img src="GV_gene_track.png"
     alt="GV gene track with or without expanded transcripts"
     width="80%">

When the genomic range selected for visualization is too wide (> 10 Mbp),
individual genes are not plotted but are substituted by a density plot as shown
below:

<img src="GV_gene_density.png"
     alt="GV gene track displayed as density plot"
     width="80%">

*Note:* The gene density visualization mode disables *Expand transcript*.

A genome label track is always shown below the genome annotation track and is
generated with the `pltgardener` function
[`annoGenomeLabel()`](https://phanstiellab.github.io/plotgardener/reference/annoGenomeLabel.html).


By default, a [Chromosome
ideogram](https://phanstiellab.github.io/plotgardener/reference/plotIdeogram.html)
is shown at the bottom of the plot area. The plotting range on the chromosome
is highlighted in red. An example is shown below:

<img src="GV_chr_highlight.png" alt="GV chromosome ideogram with highlight"
     width="80%">

The chromosome ideogram can be switched off by unchecking the *Chromosome
Ideogram* checkbox,

<img src="GV_chr_ideogram.png" alt="GV chromosome ideogram checkbox"
     width="25%">

</details>
</div>

<div>
<details open>
<summary>Analysis Tools</summary>

### Analysis Tools

***Genomic Viewer*** provides supporting functionalities designed to assist
researchers in analyzing data. They include data filtering and sorting options,
data-integration charts and basic analytical summaries.  Users can access these
features via the *Data* and *Stats* navigation tabs located in the main central
window of the application.

#### Data subsetting

Through the Data navigation tab, the user can generate subsetted versions of
supported raw data formats, including BED, BEDPE, categorical BED, and GWAS.
Sections names will be updated specifically with the user-defined dataset
labels. The application displays a preview of the subset output limited to the
first 15 rows. The complete subsetted dataset can be retrieved using the
dedicated *Download* button.

Visualization of the subset output in the main window is triggered by clicking
the *Go* button. Exporting the subsetted data enables detailed inspection of
genomic features within regions of interest and enables downstream analysis or
visualization using external tools.

#### Stats analytical summaries

The *Stats* navigation tab provides a set of charts that can be generated by
the user to support data exploration and integration. Each chart can be
produced by pressing the *Run* button in the corresponding section. Sample
names will be updated specifically with the user-defined dataset labels. The
availability of specific charts depends on the input data file format, as well
as on the size of the input file and the width of the selected genomic range.
These constraints are enforced to prevent excessive computational load and the
generation of overly large output. In case a plot is not generated due to file
size/genomic range restrictions, a warning message will appear.

The *Stats* tab is designed to enable rapid access to quantitative and
comparative insights within the data and to support lightweight data
integration visualizations, rather than to perform computationally intensive
analyses.
<!-- This is a pretty empty message. Clarify what you want to say here and
 rewrite. I cannot see what you want to deliver with this. -->

It follows a brief description of the available charts:

1. ***Peaks and arches count***: A barplot for peaks (BED files) and arches
   (BEDPE files) counts in the whole reference genome and in the user-selected
   genomic region. This is useful for looking at the relative abundance of
   peaks/arches features in the selected region compared to the entire genome.

<img src="GV_peak_count.png" alt="GV peak and arches count barplot"
     width="60%">

2. ***Peaks and arches overlap***: An upset plot showing the intersection
   between peaks or arches (BED or BEDPE files) of different samples among
   themselves. The overlap of peaks with arches is also reported.  The absolute
   number of overlapping features and their percentage are reported in the
   plots for the entire genome and for the user selected range.

<img src="GV_upset.png" alt="GV upset plot" width="60%">

3. ***Peaks Annotation***: A piechart showing peak annotations (calculated from
   BED files) across genomic functional regions, produced with the
   [ChIPpeakAnno](https://bioconductor.org/packages/release/bioc/vignettes/ChIPpeakAnno/inst/doc/ChIPpeakAnno.html)
   R package.  This plot is only generated for peaks in the whole genome,
   without subsetting the user-selected genomic range.

<img src="GV_peak_annotation.png"
     alt="GV annotation of peaks using the ChIPPeakAnno package"
     width="60%">

4. ***Circos plot for 3D contacts***: A circos plot representing a circular
   visualization of the chromosome containing the user-selected genomic range.
   Several concentric circles inside the chromosome (from outer to inner) will
   represent the 3D contact density in the whole chromosome, the contact arches
   in the chromosome, in the outer section.  The inner circles show the zoom in
   of the user-selected range with 3D arches and gene names annotations. This
   is a more compacted view to evaluate contacts in their genomic context. A
   different color is automatically assigned to each chromosome.

<img src="GV_circos.png" alt="GV circos plot of 3D contact arches" width="60%">

5. ***Categorical classification chart***: A [circular
   packing](https://r-graph-gallery.com/circle-packing.html) plot which reports
   the abundance in percent of the features in the provided [Categorical
   BED](#categorical-bed) file for either the whole genome or, if any, the
   user-selected genomic range.  This plot consists in a series of circles whose
   radius is proportional to the amount of elements classified according to the
   reported categories. Circles are also organized hierarchically, allowing to
   evaluate different types of classifications in the same plot.  This is
   particularly useful when more than one categorical BED file is provided.

<img src="GV_cat_chart.png" alt="GV categorical classification chart"
     width="60%">

6. ***Manhattan plot***: A Manhattan plot showing an enlarged view of the
   chromosome relative to the user-selected region with the IDs of the
   significant SNPs (-log(p-value) > 10<sup>-8</sup>). If the selected region
   is smaller than the entire chromosome, a zoom-in of the region with the IDs
   of the significantly associated SNPs is displayed. This allows evaluation of
   the features in the selected regions within the context of the surrounding
   genomic elements, e.g. understanding if the selected region is within or
   close to a hotspot.

<img src="GV_manhattan.png" alt="GV manhattan plot with chromosome view"
     width="60%">

Currently, these plots cannot be exported.

</details>
</div>

<div>
<details open>
<summary>Run and Export Functionalities</summary>

### Run and Export Functionalities

With ***Genomic Viewer*** it is possible to explore multiple datasets and
export a high quality image of the created visualization.

For all these operations there are three key buttons in the ***Genomic
Viewer*** interface:

- *Go* button is used to generate or update the main genomic view plot with a
  new set of user-defined parameters. The *Go* button is placed at the bottom
  of the left sidebar beside the *Save* button.

<img src="GV_go_save.png"
     alt="GV Go and Save buttons at the bottom of the lefdt sidebar"
     width="20%">

- *Save* button: once the user is satisfied with the displayed genomic view
  plot, it can be exported in the desired file format through the *Save*
  button, which will open a pop-up window. A files can be saved in either of
  the formats: SVG, PDF, PNG, or JPG.

<img src="GV_save_window.png"
     alt="GV save button and popup window with export formats"
     width="60%">

- *Data download* buttons: the tables with raw data subset to the user-selected
  genomic range can be exported for external use from the *Data* navigation
  tab.  Below each table overview there is a *Download* button which exports
  the file in the correct format appending to the file name the corresponding
  coordinates.

<img src="GV_gwas_table_example.png" alt="GV export table with data subset"
     width="60%">

</details>
</div>

------------------------------------------------------------------------

## Tutorial

<div>
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
like **peak calling**[[2]](#ref2). In addition, it is also very useful to address biological questions.
Considering the data that are loaded as usage example in the present tutorial, an interesting biological question can be to *identify SNPs (from the GWAS data) found in CKD patients that are associated to relevant genes for kidney function*.

### Genome selection, navigation and plot inspection

Before starting to inspect the data tracks it is essential to select the correct reference genome. When ***Genomic Viewer*** is started it loads by default the human *reference genome hg19* (GRCh19).
The usage example data are mapped to the human *reference genome hg38* (GRCh38). Therefore the first thing to do to ensure correct annotation of the data is to choose the right version of the genome from the top left dropdown menu.

<img src="GV_ref_genome.png" alt="GV reference genome selection" width="20%">

Since the example data used in this tutorial include the whole *chromosome 5* we can start taking an overview of the entire chromosome 5 by clicking on it form the **Choose chromosome** interactive plot
in the upper right sidebar.

<img src="GV_choose_chrom.png" alt="GV interactive chromosome hover plot" width="25%">

Upon click you will see that the coordinates are passed to the *Load coordinates* panel on the left sidebar. Make sure that the *Plot* navigation tab is selected form the main central window.
Next click the *Go button* to generate the corresponding genomic screenshot plot.

<img src="GV_navigation_tabs.png" alt="GV navigation tabs Plot selected" width="20%">

<img src="GV_chr5_overview.png" alt="GV overview of chromosome 5 example genomic tracks" width="80%">

From a quick look at the generated plot, a cluster of significant SNPs close to the right chromosome end appear from the GWAS data. It is worthy to take a close look.
For this aim the user can employ the *drag and drop zoom bar* at the bottom of the plot. In this tutorial the coordinates of the region around the SNPs cluster were already saved as custom coordinates list
and uploaded as default through the configuration file. The user can access these coordinates form the from the *Load Coordinates* panel in the left sidebar.
By clicking on the first entry in the list, the corresponding coordinates (relative to the gene SLC34A1) are passed to the tool and the *Insert Coordinates* panel will automatically update.

<img src="GV_region_table_example.png" alt="GV coordinates selection from custom list" width="25%">

As before, make sure that the *Plot* navigation tab is selected form the main central window. Next click the *Go button* to generate the corresponding genomic screenshot plot.
If you are not satisfied of the output you can adjust the selected genomic range by zooming-in and out through the zoom panel at the bottom of the *Plot tab* and
eventually save the new coordinates in the region table by clicking on the *Add button*.

<img src="GV_chr5_zoom.png" alt="GV zoom of chromosome 5 example genomic tracks" width="80%">

From the zoomed plot we can distinguish more clearly the significant SNPs, the gene in which they are found (SLC34A1) and some epigenetic features of this locus, like the presence of *regulatory elements*, *ATAC-seq peaks* and the proximity to a *3D chromatin loop* (HiC arch).


### Download of the genomic view plot

Once you are satisfied of the generated genomic view plot you can choose to download it through the *Save button* in the bottom left sidebar. This will open a popup window through which you can choose the file format
among: .pdf, .svg, .png and .jpeg. See *Export Functionalities* in the [Features and Usage](#features-and-usage) section.

<img src="GV_save_window.png" alt="GV save button and popup window with export formats" width="60%">

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

<img src="GV_gwas_table_example.png" alt="GV export table with data subset" width="60%">

### Evaluate data from stats

***Genomic Viewer*** also offers a handful of dataset-specific plots accessible from the *Stats tab*.

<img src="GV_navigation_tabs_stats.png" alt="GV navigation tabs Stats selected" width="20%">

Each of these plot can be generated by clicking the *Run* button in the corresponding section.
Since our example include all the data types associated to a Stats plot you can try to generate all of them. For a detailed description of the single plots you can refer to the *Analysis Tools* in the [Features and Usage](#features-and-usage) section.

For the purpose of this tutorial we will only describe the outputs that provides more relevant insights for the proposed biological question:

- We have a *Manhattan plot* that summarizes in a single view what we already observed from the two genomic screen that were evaluated. There is a putative risk locus with a *cluster of significant SNPs* associated with CKD in the right telomere proximal region
of chromosome 5. A zoom-in of this region is useful to visually report the *rs IDs* of the significant SNPs as an alternative to the table generated in the *Data tab*.

- From the zoomed genomic screen comprising the risk locus we noticed the presence of several *regulatory elements*. The *categorical classification* chart is useful to evaluate their enrichment compared to their abundance in the whole genome.
For instance, the locus of interest is rich in *TSS peaks* resembling gene promoters, which makes this region very interesting since SNPs can have crucial effects on transcription regulation when occurring in regulatory regions like
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
The clinical relevance of this gene product is supported by recent literature observing its downregulation in conditions of acute kidney injury (AKI)(Wilflingseder et al.)[[4]](#ref4).
For a user that would like to further investigate a molecular mechanism linking SNPs to SLC34A1 deregulation, the example data loaded into ***Genomic Viewer*** suggest that in healty condition SLC34A1 is in a context of open chromatin, and is in gene rich region with multiple regulatory elements.
Especially there is an overlap between the SNPs and an enhancer element, but also with several promoters. In turn HiC data reveal the presence of a chromatin loop that connects the region upstream to SLC34A1 promtoer with
distal elements. Altogether, these information can suggest that the presence of SNPs in the SLC34A1 locus can alter the function of epigenetic regulatory elements and the expression of the gene.
These hypothesis can be experimentally tested or addressed by integration of further genomic tracks, like RNA-seq or ChIP-seq.
This is a simple example of how the integrative visualization of genomic tracks can guide biological research to investigate otherwise unforeseen features.

</details>
</div>
------------------------------------------------------------------------

## Getting Help

<div>
<details open>
<summary>&nbsp;</summary>

For **general support** questions, **reporting a bug** or **suggest a new feature** you can create an issue in our [Github repository](https://github.com/EuracBiomedicalResearch/genomic_viewer).

For **confidential reports** you can contact us by [email](mailto:sara.lago@eurac.edu).

</details>
</div>
------------------------------------------------------------------------

## References and Links
<div>
<details open>
<summary>&nbsp;</summary>

### Data Availability

 The data employed in the *usage example tutorial* and other representative examples are publicly available from [GEO](https://www.ncbi.nlm.nih.gov/geo/), the [GWAS catalog](https://www.ebi.ac.uk/gwas/) and [ENCODE](https://www.encodeproject.org/) under the accession numbers listed below:

- HiC (GEO GSE212910)
- ATAC-seq (GEO GSE212908)
- CKD GWAS (GWAS Catalog 26831199)
- H3K27ac bam (ENCODE ENCFF119WEO)

Regulatory elements were downloaded from [UCSC Table Browser](https://genome.ucsc.edu/cgi-bin/hgTables).

The *cytoband information* that were not directly available through `plotgardener` were retrieved from:

- CHM13 (T2T): [marbl/CHM13 GitHub repo](https://github.com/marbl/CHM13)
- GRCM39 (mm29): [UCSC GoldenPath](https://hgdownload.soe.ucsc.edu/goldenPath/mm39/database/)

### Literature
*1.*<a id="ref1"></a> Kramer NE, Davis ES, Wenger CD et al. Plotgardener: cultivating precise multi-panel figures in R. Bioinformatics 2022;38:2042–5.

*2.*<a id="ref2"></a> Nakato R, Sakata T. Methods for ChIP-seq analysis: A practical workflow and advanced applications. Methods 2021;187:44–53.

*3.*<a id="ref3"></a> Fearn A, Allison B, Rice SJ et al. Clinical, biochemical, and pathophysiological analysis of SLC34A1 mutations. Physiol Rep 2018;6:e13715.

*4.*<a id="ref4"></a> Wilflingseder J, Willi M, Lee HK et al. Enhancer and super-enhancer dynamics in repair after ischemic acute kidney injury. Nat Commun 2020;11:3383.

</details>
</div>
------------------------------------------------------------------------

