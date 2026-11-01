"""
Shinrin CS — Özel Kurulum Sihirbazı (Python / Tkinter)
"""

import sys
import os
import shutil
import winreg
import subprocess
import tkinter as tk
from tkinter import messagebox
from datetime import datetime

APP_NAME = "Shinrin CS"
REG_PATH = r"SOFTWARE\ShinrinCS\InstallGuard"
MARKER_DIR = os.path.join(os.environ.get("PROGRAMDATA", "C:\\ProgramData"), "ShinrinCS")
MARKER_FILE = os.path.join(MARKER_DIR, ".installed")


def is_already_installed_or_blocked():
    """Daha önce yüklenmiş mi veya lisans gereği bloklu mu kontrol et."""
    # 1. Registry kontrolü
    try:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, REG_PATH, 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY)
        installed, _ = winreg.QueryValueEx(key, "installed")
        winreg.CloseKey(key)
        if installed == "true":
            return True
    except FileNotFoundError:
        pass

    # 2. Marker dosya kontrolü
    if os.path.exists(MARKER_FILE):
        return True

    return False


def set_install_guard():
    """Kurulum sonrasında, tekrar kurulumu kalıcı olarak engellemek için işaret bırak (Registry + Dosya)."""
    # 1. Registry'e yaz (Kalıcı)
    try:
        key = winreg.CreateKeyEx(winreg.HKEY_LOCAL_MACHINE, REG_PATH, 0, winreg.KEY_WRITE | winreg.KEY_WOW64_64KEY)
        winreg.SetValueEx(key, "installed", 0, winreg.REG_SZ, "true")
        winreg.SetValueEx(key, "install_date", 0, winreg.REG_SZ, datetime.now().isoformat())
        winreg.CloseKey(key)
    except PermissionError:
        pass # Eğer admin çalışmıyorsak diye ama admin isteyeceğiz

    # 2. Kalıcı dosyayı yaz
    try:
        os.makedirs(MARKER_DIR, exist_ok=True)
        with open(MARKER_FILE, "w", encoding="utf-8") as f:
            f.write("installed=true\n")
            f.write(f"date={datetime.now().isoformat()}\n")
            f.write("DO NOT DELETE THIS FILE. ENFORCING SINGLE INSTALL POLICY.\n")
    except Exception:
        pass


def get_desktop_path():
    """Gerçek Masaüstü dizinini bulur (OneDrive sebebiyle değişmiş olabilir)."""
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders")
        path, _ = winreg.QueryValueEx(key, "Desktop")
        winreg.CloseKey(key)
        return os.path.expandvars(path)
    except Exception:
        return os.path.join(os.environ.get('USERPROFILE', 'C:\\'), 'Desktop')


def create_shortcut(target, name):
    """Masaüstüne kısayol oluşturur."""
    desktop = get_desktop_path()
    path = os.path.join(desktop, f"{name}.url")
    target_url = target.replace('\\', '/')
    with open(path, "w", encoding="utf-8") as shortcut:
        shortcut.write("[InternetShortcut]\n")
        shortcut.write(f"URL=file:///{target_url}\n")
        shortcut.write(f"IconIndex=0\n")
        shortcut.write(f"IconFile={target}\n")


def perform_installation(root):
    """Kurulum işlemini gerçekleştirir."""
    install_dir = os.path.join(os.environ['LOCALAPPDATA'], "ShinrinCS")
    
    # Kendi dizinimiz neresi (PyInstaller MEIPASS veya mevcut py dizini)
    if hasattr(sys, '_MEIPASS'):
        base_path = sys._MEIPASS
    else:
        base_path = os.path.abspath(".")

    game_exe = os.path.join(base_path, "ShinrinCS.exe")
    
    if not os.path.exists(game_exe):
        messagebox.showerror("Hata", f"Kurulum dosyaları eksik!\n{game_exe} bulunamadı.")
        root.destroy()
        return

    try:
        # Klasörü oluştur
        os.makedirs(install_dir, exist_ok=True)
        
        # Dosyayı kopyala
        target_exe = os.path.join(install_dir, "ShinrinCS.exe")
        shutil.copy2(game_exe, target_exe)
        
        # Uninstall bat oluştur
        uninst_bat = os.path.join(install_dir, "Uninstall.bat")
        with open(uninst_bat, "w") as f:
            f.write("@echo off\n")
            f.write("echo Shinrin CS kaldiriliyor...\n")
            f.write("timeout /t 2 >nul\n")
            f.write(f'del /f /q "{target_exe}"\n')
            desktop_path = get_desktop_path()
            shortcut_path = os.path.join(desktop_path, "Shinrin CS.url")
            f.write(f'del /f /q "{shortcut_path}"\n')
            f.write("echo Uygulama kaldirildi! (Lisans kaydi korundu)\n")
            f.write("pause\n")

        # Kısayol oluştur
        create_shortcut(target_exe, "Shinrin CS")
        
        # Install guard işaretle
        set_install_guard()
        
        messagebox.showinfo("Başarılı", "Kurulum başarıyla tamamlandı!\nMasaüstündeki kısayoldan oyunu başlatabilirsiniz.")
        root.destroy()

    except Exception as e:
        messagebox.showerror("Kurulum Hatası", str(e))
        root.destroy()


def main():
    root = tk.Tk()
    root.title(f"{APP_NAME} Kurulum Sihirbazı")
    root.geometry("400x250")
    root.resizable(False, False)
    root.eval('tk::PlaceWindow . center')

    # Daha önce kurulmuş mu?
    if is_already_installed_or_blocked():
        messagebox.showerror(
            "Kurulum Engellendi",
            "Bu bilgisayarda Shinrin CS daha önce kurulmuş.\n\n"
            "Lisans politikası gereği aynı bilgisayara tekrar kurulamaz.\n"
            "Hata Kodu: SHINRIN-INSTALL-BLOCKED"
        )
        root.destroy()
        return

    # Kurulum Arayüzü
    frame = tk.Frame(root, padx=20, pady=20)
    frame.pack(fill=tk.BOTH, expand=True)

    tk.Label(frame, text=f"{APP_NAME} Kurulum", font=("Helvetica", 16, "bold")).pack(pady=(0, 10))
    tk.Label(frame, text="Tekil Kurulum Sözleşmesi:\nBu oyun cihazınıza sadece BİR KEZ kurulabilir.\nSilerseniz bir daha oynayamazsınız.", 
             fg="red", justify=tk.CENTER).pack(pady=10)

    btn_install = tk.Button(frame, text="Kabul Ediyorum ve Yükle", bg="#4CAF50", fg="white", font=("Helvetica", 11, "bold"),
                            command=lambda: perform_installation(root))
    btn_install.pack(pady=15, fill=tk.X)

    btn_cancel = tk.Button(frame, text="İptal", command=root.destroy)
    btn_cancel.pack(pady=5)

    root.mainloop()

if __name__ == "__main__":
    main()
