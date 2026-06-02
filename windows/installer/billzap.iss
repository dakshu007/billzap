; BillZap — Inno Setup installer script
; ---------------------------------------------------------------------
; Produces a single BillZap-Setup.exe that installs the Flutter Windows
; build (billzap.exe + DLLs + data/ folder) into Program Files, creates
; Start-Menu + optional desktop shortcuts, and registers an uninstaller.
;
; The CI passes two defines on the command line:
;   /DSourceDir=<path to build\windows\x64\runner\Release>
;   /DAppVersion=<x.y.z>
; with sensible fallbacks below so the script also compiles locally.

#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define AppName "BillZap"
#define AppPublisher "BillZap"
#define AppURL "https://billzap.netlify.app/"
#define AppExeName "billzap.exe"

[Setup]
; A stable GUID identifies the app for upgrades/uninstall. Generated once,
; must never change across versions or Windows treats it as a new app.
AppId={{8B2F1C4E-9A7D-4E3B-B6C1-5F0A2D9E7C84}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Per-user install needs lowest; we install for the current user so no
; admin elevation prompt — friendlier for shop owners on a single PC.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=BillZap-Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Both x64 and arm64 desktops are supported by Flutter Windows.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
SetupIconFile=..\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Pull in the entire Release folder (exe + flutter DLLs + data/ assets +
; any plugin DLLs). recursesubdirs + createallsubdirs keeps the data/
; tree intact, which Flutter needs at runtime.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Offer to launch right after install.
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
