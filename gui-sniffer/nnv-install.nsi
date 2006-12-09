!include "MUI.nsh"
Name "Network Night Vision 0.0.1"
OutFile "network-night-vision-setup-0.0.1.exe"
InstallDir "$PROGRAMFILES\Network Night Vision"
InstallDirRegKey HKLM "Software\Network Night Vision" "Install_Dir"
SetCompressor /solid lzma
  !insertmacro MUI_PAGE_LICENSE "license.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

Section "Network Night Vision (required)"
  SectionIn RO
  SetOutPath $INSTDIR
  File "network-night-vision.exe"
  File "*.dll"
  File "license.txt"
  WriteRegStr HKLM "Software\Network Night Vision" "Install_Dir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Network Night Vision" "DisplayName" "Network Night Vision"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Network Night Vision" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Network Night Vision" "NoModify" 1
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Network Night Vision" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
SectionEnd
Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\Network Night Vision"
  CreateShortCut "$SMPROGRAMS\Network Night Vision\Network Night Vision.lnk" "$INSTDIR\network-night-vision.exe" "" "$INSTDIR\network-night-vision.exe" 0
  CreateShortCut "$SMPROGRAMS\Network Night Vision\Uninstall.lnk "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
SectionEnd
Section "Uninstall"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Network Night Vision"
  DeleteRegKey HKLM "Software\Network Night Vision"
  Delete "$INSTDIR\network-night-vision.exe"
  Delete "$INSTDIR\license.txt"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\uninstall.exe"
  Delete "$SMPROGRAMS\Network Night Vision\*"
  RMDir "$SMPROGRAMS\Network Night Vision"
  RMDir "$INSTDIR"
SectionEnd

