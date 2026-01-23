
# Genomic Viewer

<img src="assets/GV_installer_logo.png" width="225"/>

**Version:** 1.0.0\
**Description:** Genomic Viewer is a cross-platform application for visualizing
and analyzing genomic data hosted in a Docker container.

------------------------------------------------------------------------

## Table of Contents

<details open>
<summary>&nbsp;</summary>

1.  [Overview](#overview)
2.  [System Requirements](#system-requirements)
3.  [Installation](#installation)
4.  [Getting Started](#getting-started)
5.  [Source Code](#source-code)

</details>

------------------------------------------------------------------------

## Overview

<details open>
<summary>&nbsp;</summary>

***Genomic Viewer*** is a graphical application for the visualization and
biological interpretation of next generation sequencing (NGS) data, focusing on
easy data integration especially for users with little to no programming
background. It combines multiple tools for genomic data exploration, filtering,
and generation of publication-ready plots into a single, easy to use program.
***Genomic Viewer*** has been designed to be of use for non-programmer users,
works offline, allows sessions sharing and performs some basic analyses for
data inspection.

<br/><br/>

![](assets/GV_main_window.png)

</details>

------------------------------------------------------------------------

## System Requirements
<details open>
<summary style="font-size: 1.3em; font-weight: bold; color:#039BE5;">
Software and Hardware
</summary>

#### <span>**Operating System**</span>

-   Windows 10 or higher
-   macOS 11 with Apple M1 ARM64 or higher
-   Linux (Debian-based or Red Hat-based)

#### <span>**Hardware Recommendations**</span>

-   Minimum RAM 4GB
-   Minimum disk space 12GB: 4GB Docker Desktop, 7.5GB Genomic Viewer Docker
    image, 350MB Genomic Viewer Installer, plus space for user defined data to
    be loaded during program invocation

</details>

------------------------------------------------------------------------

## Installation

<details open>

<summary style="font-size: 1.3em; font-weight: bold; color:#039BE5;">
Installation Instructions
</summary>

<div>

Recommended actions for the user <em>before</em> installing ***Genomic
Viewer*** and step-by-step instructions on how to get the
application running.

<br/><br/>

#### <span style = "font-size: 1.2em;">**Windows**</span>

**Prerequisites:**

-   Install [Docker Desktop for
    Windows](https://docs.docker.com/desktop/setup/install/windows-install/).
-   Enable the Windows Subsystem for [Linux
    WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) (optional, if
    not enabled ***Genomic Viewer installer*** will do this for you).
-   Download `genomicviewer-gui-installer` file for Windows from
    [GitHub](https://github.com/EuracBiomedicalResearch/genomic_viewer/tree/docker-genomicviewer/GV_installer_electron).

**Installation:**

1. Extract the `windows-x64` installer file.
2. Start setup by double-click on `genomicviewer-gui-installer-1.0.0 Setup` file.
3. Follow the installer wizard instructions.

**Uninstallation:**

1. Start `genomicviewer-gui-installer-1.0.0 Setup` file.
2. Follow the "Remove App Data" instructions to remove app-associated data. 
  (*Note: user's own data saved in the data folder are preserved*).
3. Uninstall application from `Windows Start Menu > Settings > Apps > Uninstall`.
<br/><br/>


#### <span style = "font-size: 1.2em;">**macOS**</span>

**Prerequisites:**

-   Install [Docker Desktop for
    macOS](https://docs.docker.com/desktop/setup/install/mac-install/).
-   Download `genomicviewer-gui-installer` file for macOS from
    [GitHub](https://github.com/EuracBiomedicalResearch/genomic_viewer/tree/docker-genomicviewer/GV_installer_electron).

**Installation:**

1. Extract the `macos-arm64` installer file.
2. Start setup by double-click on `GenomicViewer.dmg` file.
3. Drag the `.app` bundle to the `Application` folder.
4. Follow the installation wizard instructions.

**Uninstallation:**

1. Start `GenomicViewer.dmg` package.
2. FOllow the "Remove App Data" instructions.
3. Drag the `GenomicViewer.app` bundle to `Trash`.
<br/><br/>

#### <span style = "font-size: 1.2em;">**Linux**</span>

**Prerequisites:**

-   Install either [Docker Desktop for
    Linux](https://docs.docker.com/desktop/setup/install/linux/) or [Docker
    Engine](https://docs.docker.com/engine/install). <br> **Note:** Non-root
    users can still use docker if [rootless
    mode](https://docs.docker.com/engine/security/rootless/) is configured on
    their system.
-   Download `genomicviewer-gui-installer` file for Linux from
    [GitHub](https://github.com/EuracBiomedicalResearch/genomic_viewer/tree/docker-genomicviewer/GV_installer_electron).<br> **Note:**
    Linux installer provides both *.deb* package for Debian-based
    distributions and *.rpm* package for Red Hat-based distributions. A
    self-contained app is also available for non-root users.

**Installation:** <br>
***To install Genomic Viewer as root user:***

1. Extract the `linux-64` installer file.
2. Install the Genomic Viewer guided setup package by double-clicking on either
   `genomicviewer-gui-installer-1.0.0_amd64.deb` or
   `genomicviewer-gui-installer-1.0.0-1.x86_64.rpm` file, depending on your
   linux distribution.
3. Launch the application setup by executing
   `genomicviewer-gui-installer-1.0.0_amd64` or
   `genomicviewer-gui-installer-1.0.0-1.x86_64` command in a terminal.

***To install Genomic Viewer as non-root user:***

1. Start installation from the self-contained app image
   `genomicviewer-gui-installer-x86_64.AppImage` by running
   `./genomicviewer-gui-installer-x86_64.AppImage` or
   `./genomicviewer-gui-installer-x86_64.AppImage --no-sandbox` based on your
   Linux setup.
2. Follow the installer wizard instructions.

**Uninstallation**<br>
***For Genomic Viewer installed as root user:***
1. Launch `genomicviewer-gui-installer-1.0.0_amd64` or
   `genomicviewer-gui-installer-1.0.0-1.x86_64` command in a terminal.
2. Follow the "Remove App Data" instructions.
3. Remove the application package by running 
  `sudo apt remove genomicviewer-gui-installer-1.0.0_amd64.deb` or 
  `sudo dnf remove genomicviewer-gui-installer-1.0.0_amd64.rpm`.


***For Genomic Viewer installed as non-root user:***
1. Run the self-contained app image `genomicviewer-gui-installer-x86_64.AppImage`.
2. Follow the "Remove App Data" instructions.
3. Remove `genomicviewer-gui-installer-x86_64.AppImage`.

</div>
</details>

------------------------------------------------------------------------

## Getting Started

<details open>
<summary style="font-size: 1.3em; font-weight: bold; color:#039BE5;">
Quick Start
</summary>

<div>
A short hands-on section showing a simple workflow.

<h4><strong>1. Configuration and loading data</strong></h4>

Data and their annotation are loaded through a configuration file named
`GenomicViewer_config.yml` which is automatically saved in the `data/` folder
during ***Genomic Viewer*** installation in the user selected
location.

A default configuration file is pre-filled and ready to use with information
related to an example dataset retrieved from public data (accession numbers
GEO: GSE212908, GSE212910, GAWS catalog: 26831199 and UCSC Table Browser
Regulatory elements).  ***Note:*** example data are
provided only for ***chr5*** to reduce disk space.

For more details on how to fill the <em>Configuration file</em> see the
[Configuration
section](assets/genomicviewer-reference-manual.md#configuration). ***Genomic
Viewer*** determines the data type and label based on the configuration file
entries.

See [File Formats](assets/genomicviewer-reference-manual.md#file-formats) for
information on the supported data formats in the [Configuration
section](#configuration). Additional configuration options like track plots
alternatives, transcript or gene label annotation and chromosome display are
available from the graphical interface and are thoroughly described in the
[Features and Usage
section](assets/genomicviewer-reference-manual.md#features-and-usage). Ensure
that the data you want to load are saved in the `data/` directory that was
created upon ***GenomicViewer*** installation. Pay attention to load only data
files with matching reference genome.


<h4> <strong>2. Launch Genomic Viewer</strong> </h4>

Launch ***Genomic Viewer*** with the desktop icon that was created upon 
installation.

After loading all the required R packages ***Genomic Viewer*** interface will
open as a new tab in your default web browser.

<h4> <strong>3. Select a reference genome</strong> </h4>

***Genomic Viewer*** shows data aligned to the genomic coordinates of a
selected reference genome. It is essential to choose the correct reference
genome to avoid mislabeling of gene/transcript annotation tracks and
coordinates. Load only data tracks mapped to the same reference genome, and
choose the appropriate reference.  When you first launch the ***Genomic
Viewer*** application, it automatically loads the default reference genome
(currently hg19). For instructions on changing to another reference genome,
refer to <em>Reference Genomes</em> paragraph in the
[Features and Usage section](./genomicviewer-reference-manual.md#features-and-usage).

<h4> <strong>4. Navigate</strong> </h4>

The genomic range to be visualized can be specified in different ways thanks to
multiple navigation controls provided by the graphical interface. Possible ways are:

- Manual insertion of genomic coordinates.
- Uploading of predefined coordinate sets.
- Lookup by gene name.

Zooming also allows to adjust the view dynamically. Once the visualization is
generated through the <strong>Go</strong> button, a chromosome ideogram will
show the position and extent of the displayed region. For more details about
genomic navigation, see the <em>Genomic Navigation</em> paragraph in the
[Features and Usage
section](./genomicviewer-reference-manual.md#features-and-usage).

<h4> <strong>5. Explore datasets</strong> </h4>

***Genomic Viewer*** provides three different navigation tabs named
<strong>Plot</strong>, <strong>Data</strong> and <strong>Stats</strong> to

- extract and visualize genomic data of a selected region;
- subset the original data to the visualized genomic range, ready for export and
  external use;
- obtain quantitative and descriptive information to support the biological
  interpretation.

Further description of each panel is available at the <em>Central Panels</em>
in the [Features and Usage
section](./genomicviewer-reference-manual.md#features-and-usage) paragraph.

<h4> <strong>6. Export results and coordinates</strong> </h4>

***Genomic Viewer*** allows to export and save different outputs generated
during a working session:

- The genomic visualization can be exported as a high quality plot in different
  file formats with the <strong>Save</strong> button.
- A custom list of coordinates dynamically created during the working session
  can be exported and saved in the <strong>Load coordinates</strong> panel.
- Raw data corresponding to what is shown in the selected genomic region can be
  downloaded as individual files in the <strong>Data</strong> navigation panel.

A more in detail description of these functions is given in the [Features and
Usage section](./genomicviewer-reference-manual.md#features-and-usage).

<h4> <strong>7. Share your session</strong> </h4>

Collaborative efforts are supported by ***Genomic Viewer***. Be sure the
collaborator has all underlying data files and then simply forward the
`data/GenomicViewer_config.yml` to your partner to place it on their
installation's `data/` directory.

Several configuration files can be stored separately to keep track of multiple
working sessions. Just remember to select the proper reference genome in
***Genomic Viewer***.

</div>
</details>

------------------------------------------------------------------------

<details open>
<summary style="font-size: 1.3em; font-weight: bold; color:#039BE5;">
User Interface Overview
</summary>

<div>
Brief description of the ***Genomic Viewer*** graphical interface structure.

<h4><strong>Main Window</strong></h4>

The graphical layout of ***Genomic Viewer*** consists of three elements:

- *left sidebar* - reference genome selection, coordinates (information and
  input) and buttons for updating and saving the view;
- *right sidebar* - selection of an entire chromosome for plotting, gene search,
  advanced graphics options;
- *central panel* - for showing plots, data, and statistics.

![Figure 1. ***Genomic Viewer*** main window.](assets/GV_main_window_sections.png)

<h4><strong>Sidebars</strong></h4>

***Left sidebar***

The left sidebar provides several functions for working with the reference
genome and its navigation. First, it is essential to select the reference genome
that matches all the data files defined in the configuration file. Coordinates
can be entered manually (or are transferred and displayed from the gene search)
or can be selected from a custom list. This list of coordinates can be modified
over the course of a session and can be exported for later use in a follow-up
session or for collaborative sharing. The left sidebar is also where the *Go*
and *Save* buttons are located, which are used to update the genomic view
plot and to export it in different file formats, respectively.

***Right sidebar***

The right sidebar provides advanced options for genomic navigation and graphical
settings. An entire chromosome can be chosen from a graphical overview. Genes
can be searched and their coordinates will be transferred to the left sidebar
for updating the genomic view. Again, it's imperative to choose the intended
reference genome, as the chromosomes, gene IDs and the corresponding coordinates
change accordingly. Furthermore, the bigwig data plotting style can be changed,
one can decide between viewing gene or transcript isoforms and toggle the 
visibility of the chromosome ideogram.

<h4><strong>Central Navigation Panels</strong></h4>

The central area is the core of ***Genomic Viewer*** visualizing and summarizing
previously selected genomic data. It allows the user to navigate across three
different panels showing

- the *Plot* for the selected genomic region displaying all tracks that were
  defined in the configuration file. A *zoom* action bar is used to to adjust
  the genomic range;
- a preview of the raw *Data* restricted to the visualized genomic region with
  the possibility to download them;
- informative plots can be viewed in the *Stats* tab.

Further details are available in the [Features and Usage section](#features-and-usage).

![Figure 2. ***Genomic Viewer*** navigation panels, Plot, Data, and 
Stats.](assets/GV_navigation_panels.png)
</div>
</details>

------------------------------------------------------------------------

<details open>
<summary style="font-size: 1.3em; font-weight: bold; color:#039BE5;">
Tutorial
</summary>

<div>

A complete **Tutorial** showing a usage example with the ***Genomic Viewer***
built-in test data is described in the
[Tutorial](assets/genomicviewer-reference-manual.md#tutorial) section of the
reference manual.

------------------------------------------------------------------------

## Source Code

***Genomic Viewer*** and its [Electron](https://www.electronjs.org/)-based
***GUI installer*** source code are freely available through
[GitHub](https://github.com/EuracBiomedicalResearch/genomic_viewer) under the MIT Licence.
</div>
</details>

