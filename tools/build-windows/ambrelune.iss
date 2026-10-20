; Installateur d'Ambrelune (Inno Setup 6). Construit par build.ps1 : dist\Ambrelune-Installateur.exe
[Setup]
AppName=Ambrelune
AppVersion=1.0
AppPublisher=Grégory Cuypers
DefaultDirName={autopf}\Ambrelune
DefaultGroupName=Ambrelune
OutputBaseFilename=Ambrelune-Installateur
Compression=lzma2/max
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
UninstallDisplayIcon={app}\Ambrelune.exe
DisableProgramGroupPage=yes

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
Source: "..\..\dist\Ambrelune.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Ambrelune"; Filename: "{app}\Ambrelune.exe"
Name: "{autodesktop}\Ambrelune"; Filename: "{app}\Ambrelune.exe"; Tasks: bureau

[Tasks]
Name: "bureau"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"

[Run]
Filename: "{app}\Ambrelune.exe"; Description: "Lancer Ambrelune"; Flags: nowait postinstall skipifsilent
