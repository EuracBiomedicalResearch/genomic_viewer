
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  checkDocker: () => ipcRenderer.invoke('check-docker'),
  openDockerDesktop: () => ipcRenderer.invoke('open-docker-desktop'),
  pullDockerImage: (name) => ipcRenderer.invoke('pull-docker-image', name),
  checkWSL: () => ipcRenderer.invoke('check-wsl'),
  installWSL: () => ipcRenderer.invoke('install-wsl'),
  platform: process.platform,
  chooseLauncherLocation: () => ipcRenderer.invoke('choose-launcher-location'),
  saveLauncherFile: (info) => ipcRenderer.invoke('save-launcher-file', info),
  copyConfigFile: (info) => ipcRenderer.invoke('copy-config-file', info),
  copyExampleData: (info) => ipcRenderer.invoke('copy-example-data', info),
  createShortcut: (info) => ipcRenderer.invoke('create-shortcut', info),
  exitApp: () => ipcRenderer.invoke('exit-app'),
  removeAppData: () => ipcRenderer.invoke('remove-app-data')
});
