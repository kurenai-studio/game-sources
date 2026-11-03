// Electron main process: opens the game in a normal desktop window.
const { app, BrowserWindow, Menu } = require('electron');

function createWindow() {
  const win = new BrowserWindow({
    width: 1280, height: 760, minWidth: 900, minHeight: 600,
    backgroundColor: '#101116', title: 'Type Clash', autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true }
  });
  Menu.setApplicationMenu(null);
  win.loadFile('index.html');
  // F11 toggles fullscreen
  win.webContents.on('before-input-event', (e, input) => {
    if (input.type === 'keyDown' && input.key === 'F11') win.setFullScreen(!win.isFullScreen());
  });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
