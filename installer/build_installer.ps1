param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$OutputPath=[System.IO.Path]::GetFullPath($OutputPath)
$destDir=Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$iexpress=Join-Path $env:WINDIR 'System32\iexpress.exe'
if(!(Test-Path $iexpress)){throw 'IExpress não foi encontrado neste Windows.'}
$files=@('.gitignore','INSTRUCOES_RAPIDAS.txt','README.md','README_APP.md','app_server.py','cargas_exemplo.xlsx','config.example.json','consultar.py','diagnosticar_filtrar.py','inspecionar.py','login.py','nucleo.py','requirements.txt','start_app.ps1','verificar_ambiente.py','webapp\app.js','webapp\icon.svg','webapp\index.html','webapp\manifest.json','webapp\styles.css','webapp\sw.js','installer\start_login.ps1')
$stage=Join-Path $env:TEMP ('ComproveiSetup-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
  $payloadRoot=Join-Path $stage 'payload'; New-Item -ItemType Directory -Force -Path $payloadRoot | Out-Null
  foreach($rel in $files){$src=Join-Path $root $rel; if(!(Test-Path -LiteralPath $src -PathType Leaf)){throw "Arquivo de origem ausente: $rel"}; $dst=Join-Path $payloadRoot $rel; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null; Copy-Item -LiteralPath $src -Destination $dst}
  Compress-Archive -Path (Join-Path $payloadRoot '*') -DestinationPath (Join-Path $stage 'payload.zip') -CompressionLevel Optimal
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Install.ps1') -Destination (Join-Path $stage 'Install.ps1')
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'SetupGui.ps1') -Destination (Join-Path $stage 'SetupGui.ps1')
  $sed=@"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=1
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$OutputPath
FriendlyName=Comprovei App Setup
AppLaunched=powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File SetupGui.ps1
PostInstallCmd=<None>
FILE0="Install.ps1"
FILE1="payload.zip"
FILE2="SetupGui.ps1"
[SourceFiles]
SourceFiles0=$stage\
[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
"@
  $sedPath=Join-Path $stage 'setup.sed'; [System.IO.File]::WriteAllText($sedPath,$sed,[System.Text.Encoding]::ASCII)
  if(Test-Path -LiteralPath $OutputPath){Remove-Item -LiteralPath $OutputPath -Force}
  $process=Start-Process -FilePath $iexpress -ArgumentList @('/N','/Q',$sedPath) -Wait -PassThru
  if($process.ExitCode -ne 0 -or !(Test-Path -LiteralPath $OutputPath)){throw "IExpress não gerou o instalador (exit $($process.ExitCode))."}
  Write-Host "Instalador criado: $OutputPath"
} finally {if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force}}



