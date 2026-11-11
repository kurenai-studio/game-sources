Unicode true
!include "MUI2.nsh"
!ifndef PAYLOAD
!error "PAYLOAD must point to the complete Windows payload."
!endif
!ifndef OUTPUT
!error "OUTPUT must name the installer."
!endif
Name "Horse Racing"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\Horse Racing"
RequestExecutionLevel user
SetCompressor /SOLID lzma
VIProductVersion "0.22.0.0"
VIAddVersionKey /LANG=1033 "ProductName" "Horse Racing"
VIAddVersionKey /LANG=1033 "FileDescription" "Horse Racing Installer"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Copyright 2026 Jim Holtz"
VIAddVersionKey /LANG=1033 "FileVersion" "0.22.0"
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PAYLOAD}\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Horse Racing" SEC_GAME
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File "${PAYLOAD}\Horse Racing.exe"
  File "${PAYLOAD}\Horse Racing.pck"
  File "${PAYLOAD}\LICENSE"
  File "${PAYLOAD}\THIRD_PARTY_NOTICES.md"
  File "${PAYLOAD}\README.txt"
  SetOutPath "$INSTDIR\docs"
  File "${PAYLOAD}\docs\QUICK_START.html"
  File "${PAYLOAD}\docs\USER_MANUAL.html"
  SetOutPath "$INSTDIR\licenses"
  File "${PAYLOAD}\licenses\*"
  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\Horse Racing"
  CreateShortcut "$SMPROGRAMS\Horse Racing\Horse Racing.lnk" "$INSTDIR\Horse Racing.exe"
  CreateShortcut "$SMPROGRAMS\Horse Racing\Quick Start.lnk" "$INSTDIR\docs\QUICK_START.html"
  CreateShortcut "$SMPROGRAMS\Horse Racing\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "DisplayName" "Horse Racing"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "DisplayVersion" "0.22.0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "Publisher" "Jim Holtz"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$INSTDIR\Horse Racing.exe"
  Delete "$INSTDIR\Horse Racing.pck"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\THIRD_PARTY_NOTICES.md"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\docs\QUICK_START.html"
  Delete "$INSTDIR\docs\USER_MANUAL.html"
  Delete "$INSTDIR\licenses\GODOT-LICENSE.txt"
  Delete "$INSTDIR\licenses\GODOT-COPYRIGHT.txt"
  Delete "$INSTDIR\licenses\NSIS-COPYING.txt"
  Delete "$INSTDIR\licenses\AUDIO-NOTICE.txt"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR\docs"
  RMDir "$INSTDIR\licenses"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\Horse Racing\Horse Racing.lnk"
  Delete "$SMPROGRAMS\Horse Racing\Quick Start.lnk"
  Delete "$SMPROGRAMS\Horse Racing\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Horse Racing"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HorseRacingSD"
SectionEnd
