; Shinrin CS — Inno Setup Installer Script
; Tekil kurulum koruması: bir kez kurulup silindikten sonra
; aynı PC'ye tekrar kurulamaz.

#define MyAppName "Shinrin CS"
#define MyAppVersion "1.0"
#define MyAppPublisher "Shinrin Studios"
#define MyAppExeName "ShinrinCS.exe"

[Setup]
AppId={{B7E3F2A1-5D4C-4E8B-9F6A-1C2D3E4F5A6B}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
; Bu betik packaging/ altinda; yollar proje kokune goredir
SourceDir=..
OutputDir=installer_output
OutputBaseFilename=ShinrinCS_Setup
Compression=lzma2/ultra64
SolidCompression=yes
SetupIconFile=
WizardStyle=modern
PrivilegesRequired=admin

; ══════════════════════════════════════════════════
;  TEKİL KURULUM KORUMASI
;  Registry anahtarı: HKLM\SOFTWARE\ShinrinCS\InstallGuard
;  Bu anahtar kurulum sırasında oluşturulur.
;  Kaldırma sırasında SİLİNMEZ → tekrar kurulumu engeller.
; ══════════════════════════════════════════════════

[Registry]
; Kurulum sırasında oluşturulan kalıcı anahtar
Root: HKLM; Subkey: "SOFTWARE\ShinrinCS\InstallGuard"; ValueType: string; ValueName: "installed"; ValueData: "true"; Flags: createvalueifdoesntexist

; AppData marker dosyası oluşturmak için
Root: HKLM; Subkey: "SOFTWARE\ShinrinCS\InstallGuard"; ValueType: string; ValueName: "install_date"; ValueData: "{code:GetDateTime}"; Flags: createvalueifdoesntexist

; Kurulum sayacı (her zaman artırılır)
Root: HKLM; Subkey: "SOFTWARE\ShinrinCS\InstallGuard"; ValueType: dword; ValueName: "install_count"; ValueData: "1"; Flags: createvalueifdoesntexist

[Files]
Source: "dist\ShinrinCS.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "settings.json"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Shinrin CS'yi Başlat"; Flags: nowait postinstall skipifsilent

; ══════════════════════════════════════════════════
;  KALDIRIM (UNINSTALL)
;  Registry anahtarı KALDIRILMAZ — bu sayede tekrar
;  kurulum engellenmiş olur.
;  Sadece uygulama dosyaları silinir.
; ══════════════════════════════════════════════════

[UninstallDelete]
Type: filesandordirs; Name: "{app}\saves"
Type: filesandordirs; Name: "{app}\settings.json"

[Code]
// ─── Yardımcı: Tarih/Saat ───
function GetDateTime(Param: String): String;
begin
  Result := GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':');
end;

// ─── TEKİL KURULUM KONTROLÜ ───
// Kurulumdan önce registry kontrolü yapar.
// Eğer anahtar zaten varsa → kurulum engellenir.
function InitializeSetup(): Boolean;
var
  InstalledValue: String;
begin
  Result := True;

  // Registry'de kurulum kaydı var mı kontrol et
  if RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SOFTWARE\ShinrinCS\InstallGuard',
    'installed', InstalledValue) then
  begin
    if InstalledValue = 'true' then
    begin
      // Zaten kurulmuş — tekrar kurulumu engelle
      MsgBox(
        'Bu bilgisayarda Shinrin CS daha önce kurulmuş.' + #13#10 +
        'Lisans politikası gereği aynı bilgisayara tekrar kurulamaz.' + #13#10 + #13#10 +
        'Hata Kodu: SHINRIN-INSTALL-BLOCKED' + #13#10 +
        'Destek: support@shinrin.dev',
        mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;

  // İlk kurulum — marker dosyasını da oluştur
  SaveStringToFile(
    ExpandConstant('{commonappdata}\ShinrinCS\.installed'),
    'installed=true' + #13#10 +
    'date=' + GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':') + #13#10,
    False);
end;

// ─── KALDIRMA SONRASI ───
// Marker dosyası ve registry anahtarı KALDIRILMAZ!
// Bu, tekrar kurulumu kalıcı olarak engeller.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Onay mesajı
    MsgBox(
      'Shinrin CS kaldırıldı.' + #13#10 +
      'Not: Lisans politikası gereği bu bilgisayara tekrar kurulamaz.',
      mbInformation, MB_OK);
  end;
end;
