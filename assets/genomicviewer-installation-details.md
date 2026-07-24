
# Genomic Viewer Installation Guide

<img src="GV_docker_logo.png" width="150"/>

**Version:** 1.0.0\
**Description:** Genomic Viewer is a cross-platform application for visualizing
and analyzing genomic data hosted in a Docker container.

------------------------------------------------------------------------

## Table of Contents

<details open>
<summary>&nbsp;</summary>

1. [Detailed installation through installation wizard](#detailed-installation-through-installation-wizard)
2. [Detailed installation for macOS](#detailed-installation-for-macos)

</details>

------------------------------------------------------------------------

In the following guide you can find step-by-step instructions to install
***Genomic Viewer***.
If you encounter any problem, please report it by creating a 
[GitHub issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-an-issue) 
or contacting us [directly](mailto:sara.lago@eurac.edu).

## Detailed installation through installation wizard

<details open>
<summary>&nbsp;</summary>

1. Ensure you meet all the [prerequisites](README.md#installation) for a successful 
***Genomic Viewer (GV)*** installation. Here is a checklist:

  - Docker is installed. ✅
  - WSL is enabled. ✅
  - You have downloaded ***GV*** release for Windows (see below). ✅
  
  
2. Download ***GV*** installer from GitHub:

  i) Go to the [releases](https://github.com/EuracBiomedicalResearch/genomic_viewer/releases)
     page of the ***Genomic Viewer*** GitHub repository.
     
<img src="GV_github_release.png" width="80%"/> # Replace this with correct image once we have the new release!!
     
     
  ii) Under assets click on the installer file specific to your OS to start its download.
  
<img src="GV_installer_win.png" width="80%"/> # Replace this with correct image once we have the new release!!
     


3. Launch installer wizard:
     

  i) Once download has completed, unzip the file by `right click > Extract all`.
       Go to `windows-x64 > squirrel.windows > x64` and double click on  
       `genomicviewer-gui-installer-1.0.0 Setup` to start the installation wizard.
       
  ii) Select `Start Installation` from the installation wizard and inspect the log 
      messages for any installation issue or required action. 
      
<img src="GV_installer_wizard.png" width="60%"/>

      
  iii) The installer will open a file explorer from which you can choose the directory 
     in which to save the demo data, configuration file and ***GV*** launcher script.
     
<img src="GV_install_location.png" width="80%"/>

     
  iv) When installation is completed you can click on the `Finish` button to 
      close the installer wizard.
      
<img src="GV_install_finish.png" width="60%"/>

      
  vi) You can now start ***GV*** by double-click on its Desktop icon.
  
 

</details>

------------------------------------------------------------------------

## Detailed installation for macOS

<details open>
<summary>&nbsp;</summary>

1. Ensure you meet all the [prerequisites](README.md#installation) for a successful 
***Genomic Viewer (GV)*** installation. Here is a checklist:

  - Docker is installed. ✅
  - You have downloaded ***GV*** release for macOS (see step 2 below). ✅
  
  For users without root privileges Docker can be installed as follow:
  
  i) Download [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/).
  
  ii) Instead of dragging `Docker icon file` to `Applications`, create your own 
      `apps` directory in a desired location. Next drag and drop `Docker icon file`
      into your `apps` directory.
      
<img src="GV_docker_drag_macos.png" width="80%"/>


  iii) Start Docker and follow installation instructions. In the configuration
       page select `Use advanced settings` > `User` > 
       `Automatically check configuration` > `Finish`.
       
<img src="GV_docker_configuration_noroot_macos.png" width="80%"/>

  
2. Download ***GV*** installer from GitHub:

  i) Go to the [releases](https://github.com/EuracBiomedicalResearch/genomic_viewer/releases)
     page of the ***Genomic Viewer*** GitHub repository.

<img src="GV_github_release.png" width="80%"/> # Replace this with correct image once we have the new release!!

     
  ii) Under assets click on the installer file specific to your OS to start its download.
  
<img src="GV_installer_win.png" width="80%"/> # Replace this with correct image once we have the new release!!

     

3. Launch ***GV*** directly:

  i) Once download has completed, extract the `genomicviewer-run-macos.zip` in 
     the desired location.
     
  ii) Right click on `genomicviewer-run-macos` extracted directory and choose
      `Services > New Terminal at Folder`.
      
<img src="GV_run_macOS.png" width="80%"/>

      
  If you don't see this option, enable it:
  
  - Open `System Settings → Keyboard → Keyboard Shortcuts`.
  - Go to `Services`.
  - Under `Files and Folders`, enable `New Terminal at Folder` (and/or` New Terminal Tab at Folder`).
  
<img src="GV_terminal_settings.png" width="80%"/>


  iii) If you are running ***GV*** without root privileges export Docker binaries 
       to `PATH` by typing:
       
     ```
     export PATH="$HOME/.docker/bin:$PATH"
     ```
       
   Otherwise skip this step.
  
  iv) Type the following command in terminal `docker compose up`.
       This will pull the docker image if not already present, or directly run
       ***GV*** application.
       
  <img src="GV_docker_compose.png" width="80%"/>
  
       
  v) Once loading is finished and the following link appears in Terminal 
      `http://0.0.0.0:8180`, copy and paste it in a browser window to use the 
      ***GV*** application.
      Alternatively, you can use `http://127.0.0.1:8180`.
      
      
  <img src="GV_container_run.png" width="80%"/>
  
  
  <img src="GV_safari_window.png" width="80%"/>
  

</details>


------------------------------------------------------------------------

