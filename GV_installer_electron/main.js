const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { spawn, exec } = require('child_process');
const createDesktopShortcut = require('create-desktop-shortcuts');

// ----------------------------
// Handle Squirrel Events first
// ----------------------------
const squirrelEvent = process.argv[1];
if (squirrelEvent) {
  switch (squirrelEvent) {
    case '--squirrel-install':
    case '--squirrel-updated':
    case '--squirrel-uninstall':
    case '--squirrel-obsolete':
      console.log('Squirrel event detected:', squirrelEvent);
      app.quit(); // quit immediately
      process.exit(0); // stop further JS execution
      break;
    default:
      break;
  }
} 

// Create main window
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 750,
    height: 735,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  mainWindow.loadFile('index.html');
}

// Prevent multiple instances opening
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit(); // another instance is already running
} else {
  app.on('second-instance', () => {
    // Focus the existing window if someone tries to open another
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  app.whenReady().then(createWindow);

  // Optional: Handle macOS dock icon behavior
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
}

// Quit on all windows closed (except macOS)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Check if Docker is installed
ipcMain.handle('check-docker', async () => {
  return new Promise((resolve) => {
    const check = spawn('docker', ['version']);

    let output = '';
    let errorOutput = '';

    let didError = false;

    // Docker command found and started
    check.stdout.on('data', (data) => {
      output += data.toString();
    });

    check.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    check.on('error', (err) => {
      if (err.code === 'ENOENT') {
        // 'docker' command not found
        didError = true;
        resolve({ installed: false, running: false });
      } else {
        // Some other error starting docker
        didError = true;
        resolve({ installed: false, running: false, error: err.message });
      }
    });

    check.on('close', (code) => {
      if (didError) return; // Already handled in 'error' event

      if (code === 0) {
        resolve({ installed: true, running: true, version: output.trim() });
      } else {
        // Analyze stderr to determine if it's a daemon issue
        if (errorOutput.includes('Cannot connect to the Docker daemon')) {
          resolve({ installed: true, running: false });
        } else {
          // Unknown error, still installed
          resolve({
            installed: true,
            running: false,
            error: errorOutput.trim() || `Exited with code ${code}`,
          });
        }
      }
    });
  });
});


// Open Docker Desktop
ipcMain.handle('open-docker-desktop', async () => {
  try {
    if (process.platform === 'win32') {
      exec('"C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe"');
    } else if (process.platform === 'darwin') {
      exec('open -a Docker');
    } else {
      return { success: false, error: 'Manual start required on Linux' };
    }
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// Pull Docker image for Genomic Viewer
ipcMain.handle('pull-docker-image', async (event, imageName) => {
  return new Promise((resolve) => {
    const pull = spawn('docker', ['pull', imageName], { shell: true });

    let output = '';
    let errorOutput = '';

    pull.stdout.on('data', (data) => {
      output += data.toString();
    });

    pull.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    pull.on('close', (code) => {
      if (code === 0) {
        resolve({ success: true, output });
      } else {
        resolve({ success: false, error: errorOutput });
      }
    });

    pull.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });
  });
});

// Check if WSL (Windows Subsystem for Linux) is installed
ipcMain.handle('check-wsl', async () => {
  if (process.platform !== 'win32') {
    return { supported: false, installed: true }; // skip on non-Windows
  }

  return new Promise((resolve) => {
    const check = spawn('wsl', ['--status'], { shell: true });

    let output = '';
    let errorOutput = '';

    check.stdout.on('data', (data) => {
      output += data.toString();
    });

    check.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    check.on('error', (err) => {
      if (err.code === 'ENOENT') {
        resolve({ supported: true, installed: false });
      } else {
        resolve({ supported: true, installed: false, error: err.message });
      }
    });

    check.on('close', (code) => {
      if (code === 0) {
        resolve({ supported: true, installed: true, output });
      } else {
        resolve({ supported: true, installed: false, error: errorOutput });
      }
    });
  });
});

// Install WSL
ipcMain.handle('install-wsl', async () => {
  if (process.platform !== 'win32') {
    return { supported: false, success: false, message: 'WSL is only available on Windows.' };
  }

  return new Promise((resolve) => {
    const install = spawn('wsl', ['--install'], { shell: true });

    let output = '';
    let errorOutput = '';

    install.stdout.on('data', (data) => {
      output += data.toString();
    });

    install.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    install.on('close', (code) => {
      if (code === 0) {
        resolve({
          supported: true,
          success: true,
          message: 'WSL installation completed. Please restart your computer to finish setup.',
        });
      } else {
        resolve({
          supported: true,
          success: false,
          message: errorOutput || 'Failed to install WSL. Please try manually.',
        });
      }
    });

    install.on('error', (err) => {
      resolve({ supported: true, success: false, message: err.message });
    });
  });
});

// Choose location for saving bat or other executable file for the app
ipcMain.handle('choose-launcher-location', async () => {
  const platform = process.platform;
  let defaultFileName = '';
  let filters = [];

  // Detect platform and set filename + filters
  if (platform === 'win32') {
    defaultFileName = 'GenomicViewer_win.bat';
    filters = [{ name: 'Batch Files', extensions: ['bat'] }];
  } else if (platform === 'linux') {
    defaultFileName = 'GenomicViewer_linux.sh';
    filters = [{ name: 'Shell Scripts', extensions: ['sh'] }];
  } else if (platform === 'darwin') {
    defaultFileName = 'GenomicViewer_mac.sh';
    filters = [{ name: 'Shell Scripts', extensions: ['sh'] }];
  } else {
    return { canceled: true, error: 'Unsupported OS' };
  }

  const result = await dialog.showSaveDialog({
    title: 'Save Genomic Viewer Launcher',
    defaultPath: defaultFileName,
    filters,
  });

  if (result.canceled) return { canceled: true };

  const scriptPath = result.filePath;
  const dataDir = path.join(path.dirname(scriptPath), 'data');

  return {
    canceled: false,
    scriptPath,
    dataDir,
    platform,
  };
});

// Save the executable file
ipcMain.handle('save-launcher-file', async (event, { scriptPath, platform }) => {
  try {
    let fileName;

    if (platform === 'win32') {
      fileName = 'GenomicViewer_win.bat';
    } else if (platform === 'linux') {
      fileName = 'GenomicViewer_linux.sh';
    } else if (platform === 'darwin') {
      fileName = 'GenomicViewer_mac.sh';
    } else {
      throw new Error('Unsupported platform');
    }

    const sourceScript = path.join(__dirname, 'assets', fileName);
    fs.copyFileSync(sourceScript, scriptPath);

    // Make it executable (only for Linux/macOS)
    if (platform !== 'win32') {
      fs.chmodSync(scriptPath, 0o755);
    }

    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});


// Copy the config files in data subfolder
ipcMain.handle('copy-config-file', async (event, { dataDir }) => {
  try {
    fs.mkdirSync(dataDir, { recursive: true });
    const sourceConfig = path.join(__dirname, 'assets', 'GenomicViewer_config.yml');
    const destConfig = path.join(dataDir, 'GenomicViewer_config.yml');
    fs.copyFileSync(sourceConfig, destConfig);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// Copy the example data files and subfolders structure into the data directory
const copyFolderRecursive = (src, dest) => {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }

  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyFolderRecursive(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
};

ipcMain.handle('copy-example-data', async (event, { dataDir }) => {
  try {
    const sourceDir = path.join(__dirname, 'assets', 'example_data');
    copyFolderRecursive(sourceDir, dataDir);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// Create Desktop shortcut


const shortcutLib = require('create-desktop-shortcuts/src/library.js');

// Improved patch for correct VBS path resolution in packaged and dev modes
function getVbsPath() {
  if (app.isPackaged) {
    return path.join(
      process.resourcesPath,
      'app.asar.unpacked',
      'assets',
      'create-desktop-shortcuts',
      'src',
      'windows.vbs'
    );
  } else {
    return path.join(
      __dirname,
      'assets',
      'create-desktop-shortcuts',
      'src',
      'windows.vbs'
    );
  }
}

shortcutLib.produceWindowsVBSPath = () => {
  const vbsPath = getVbsPath();
  if (!fs.existsSync(vbsPath)) {
    console.error('VBScript file not found at:', vbsPath);
  } else {
    console.log('VBScript file found at:', vbsPath);
  }
  return vbsPath;
};

// Build path to resources for the icon Files
const getAssetPath = (filename) => {
  if (app.isPackaged) {
    // in packaged mode, assets are unpacked alongside the app.asar in resources
    return path.join(process.resourcesPath, 'app.asar.unpacked','assets', filename);
  } else {
    // in dev mode, use __dirname
    return path.join(__dirname, 'assets', filename);
  }
};

ipcMain.handle('create-shortcut', async (event, { scriptPath }) => {
  const desktopPath = path.join(os.homedir(), 'Desktop');

  const shortcutOptions = {
    onlyCurrentOS: true,
  };

  if (process.platform === 'win32') {
    // No need to re-check here since monkey patch logs already
    shortcutOptions.windows = {
      filePath: scriptPath,
      outputPath: desktopPath,
      name: 'Genomic Viewer',
      icon: getAssetPath('GV_icon.ico')
    };
  } else if (process.platform === 'linux') {
    shortcutOptions.linux = {
      filePath: scriptPath,
      outputPath: desktopPath,
      name: 'Genomic Viewer',
      icon: getAssetPath('GV_icon.png'),
    };
  } else if (process.platform === 'darwin') {
    shortcutOptions.osx = {
      filePath: scriptPath,
      outputPath: desktopPath,
      name: 'Genomic Viewer',
      icon: getAssetPath('GV_icon.icns'),
      overwrite: true,
    };
  }

  const result = createDesktopShortcut(shortcutOptions);
  
  // Patch ONLY Linux desktop file to add Terminal=true so that the app opens also a terminal to watch progress and messages
  if (process.platform === 'linux') {
  const desktopFile = path.join(desktopPath, 'Genomic Viewer.desktop');

  try {
    if (fs.existsSync(desktopFile)) {
      let content = fs.readFileSync(desktopFile, 'utf8');

      // Add Terminal=true if missing or false
      if (!content.includes('Terminal=')) {
        content = content.replace(
          /\[Desktop Entry\]/,
          '[Desktop Entry]\nTerminal=true'
        );
        fs.writeFileSync(desktopFile, content, { mode: 0o755 });
        console.log('Updated .desktop file with Terminal=true');
      } else if (content.includes('Terminal=false')) {
        content = content.replace(
		/Terminal\s*=\s*false/i, 
		'Terminal=true'
		);
        fs.writeFileSync(desktopFile, content, { mode: 0o755 });
        console.log('Updated .desktop file with Terminal=true');
      }

      // Fix AppImage tmp icon path
      const tmpUsrRegex = /\/tmp\/[^\/]+\/usr\//g;
      if (tmpUsrRegex.test(content)) {
        const fixedContent = content.replace(tmpUsrRegex, '/usr/');
        fs.writeFileSync(desktopFile, fixedContent, { mode: 0o755 });
        console.log('Icon path fixed in .desktop file');
      }
    }
  } catch (err) {
    console.error('Failed to patch .desktop file:', err);
  }
}

return { success: result };
});


// Exit app when click on Finish
ipcMain.handle('exit-app', () => {
  app.quit();
});
