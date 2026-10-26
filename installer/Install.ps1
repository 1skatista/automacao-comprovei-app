param([Parameter(Mandatory=$true)][string]$InstallRoot)
$ErrorActionPreference='Stop'
$install=[System.IO.Path]::GetFullPath($InstallRoot.Trim())
$state=Join-Path $env:LOCALAPPDATA 'ComproveiApp'
New-Item -ItemType Directory -Force -Path $state | Out-Null
$log=Join-Path $state 'installer.log'
try { Start-Transcript -LiteralPath $log -Append | Out-Null } catch {}
function Say($text) { Write-Host "`n$text" -ForegroundColor Cyan }
function Find-Python314 {
  $launcher=Get-Command py.exe -ErrorAction SilentlyContinue
  if($launcher){$candidate=& $launcher.Source -3.14 -c "import sys; print(sys.executable)" 2>$null; if($LASTEXITCODE -eq 0 -and $candidate -and (Test-Path $candidate.Trim())){return $candidate.Trim()}}
  $candidates=@((Join-Path $env:LOCALAPPDATA 'Programs\Python\Python314\python.exe'),(Join-Path $env:ProgramFiles 'Python314\python.exe'))
  foreach($candidate in $candidates){if($candidate -and (Test-Path $candidate)){return $candidate}}
  return $null
}
function Find-Chrome {
  $paths=@((Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),(Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),(Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'))
  foreach($candidate in $paths){if($candidate -and (Test-Path $candidate)){return $candidate}}
  return $null
}
try {
  if($env:OS -ne 'Windows_NT'){throw 'Este instalador é somente para Windows 10/11.'}
  if(-not [Environment]::Is64BitOperatingSystem){throw 'O app exige Windows 64 bits.'}
  if(-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'payload.zip'))){throw 'Pacote do app ausente ou corrompido. Baixe o instalador novamente.'}
  New-Item -ItemType Directory -Force -Path $install | Out-Null
  Say "Instalando arquivos em: $install"
  $expanded=Join-Path $PSScriptRoot 'payload'
  Expand-Archive -LiteralPath (Join-Path $PSScriptRoot 'payload.zip') -DestinationPath $expanded -Force
  Get-ChildItem -LiteralPath $expanded -Force | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $install -Recurse -Force}
  $python=Find-Python314
  if(-not $python){
    Say 'Baixando Python 3.14.9 do site oficial...'
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $download=Join-Path $env:TEMP 'python-3.14.9-amd64.exe'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://www.python.org/ftp/python/3.14.9/python-3.14.9-amd64.exe' -OutFile $download
    if((Get-Item -LiteralPath $download).Length -lt 10000000){throw 'O download do Python ficou incompleto. Verifique sua internet e execute o instalador novamente.'}
    $sig=Get-AuthenticodeSignature -LiteralPath $download
    if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Python Software Foundation'){throw 'Não foi possível validar a assinatura do instalador Python; por segurança, o app não continuou.'}
    $pythonHome=Join-Path $env:LOCALAPPDATA 'Programs\Python\Python314'
    $args=@('/quiet','InstallAllUsers=0',"TargetDir=`"$pythonHome`"",'Include_launcher=1','Include_pip=1','Include_test=0','PrependPath=0')
    $proc=Start-Process -FilePath $download -ArgumentList $args -Wait -PassThru
    if($proc.ExitCode -notin @(0,3010)){throw "Instalação do Python terminou com código $($proc.ExitCode). Consulte o log: $log"}
    $python=Join-Path $pythonHome 'python.exe'
    if(-not (Test-Path $python)){throw 'Python não foi localizado após a instalação.'}
  }
  Say 'Verificando o Google Chrome...'
  $chrome=Find-Chrome
  if(-not $chrome){
    $winget=Get-Command winget.exe -ErrorAction SilentlyContinue
    if(-not $winget){throw 'Google Chrome não encontrado e winget indisponível. Instale o Chrome e clique em Prosseguir novamente.'}
    & $winget.Source install --id Google.Chrome --exact --accept-package-agreements --accept-source-agreements
    if($LASTEXITCODE -ne 0){throw 'Não foi possível instalar o Chrome automaticamente. Instale o Google Chrome e clique em Prosseguir novamente.'}
    $chrome=Find-Chrome
    if(-not $chrome){throw 'Chrome instalado, mas não localizado. Reinicie o Windows e execute novamente.'}
  }
  Say 'Preparando o ambiente e instalando bibliotecas (pode levar alguns minutos)...'
  $venv=Join-Path $install '.venv'; $venvPython=Join-Path $venv 'Scripts\python.exe'
  $recreate= -not (Test-Path $venvPython)
  if(-not $recreate){$version=& $venvPython -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null; $recreate=($LASTEXITCODE -ne 0 -or $version.Trim() -ne '3.14')}
  if($recreate){if(Test-Path $venv){Remove-Item -LiteralPath $venv -Recurse -Force}; & $python -m venv $venv; if($LASTEXITCODE -ne 0){throw 'Não foi possível criar o ambiente Python.'}}
  $venvPython=Join-Path $venv 'Scripts\python.exe'
  & $venvPython -m pip install --disable-pip-version-check --retries 3 --timeout 30 -r (Join-Path $install 'requirements.txt')
  if($LASTEXITCODE -ne 0){throw 'Falha ao instalar as bibliotecas. Verifique a internet e clique em Prosseguir novamente.'}
  $profile=Join-Path $state 'perfil_chrome'; New-Item -ItemType Directory -Force -Path $profile | Out-Null
  $configPath=Join-Path $install 'config.json'
  if(Test-Path $configPath){$cfg=Get-Content -Raw -Encoding UTF8 $configPath | ConvertFrom-Json}else{$cfg=Get-Content -Raw -Encoding UTF8 (Join-Path $install 'config.example.json') | ConvertFrom-Json}
  $cfg.chrome_caminho=$chrome.Replace('\','/'); $cfg.perfil_dir=$profile.Replace('\','/')
  [System.IO.File]::WriteAllText($configPath,($cfg | ConvertTo-Json -Depth 20),[System.Text.UTF8Encoding]::new($false))
  Say 'Criando atalhos...'
  $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Comprovei App'; New-Item -ItemType Directory -Force -Path $menu | Out-Null
  $shell=New-Object -ComObject WScript.Shell; $powershell=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $lnk=$shell.CreateShortcut((Join-Path $menu 'Iniciar Comprovei App.lnk')); $lnk.TargetPath=$powershell; $lnk.Arguments="-NoExit -ExecutionPolicy Bypass -File `"$(Join-Path $install 'start_app.ps1')`""; $lnk.WorkingDirectory=$install; $lnk.Save()
  $lnk=$shell.CreateShortcut((Join-Path $menu '1 - Fazer login no Comprovei.lnk')); $lnk.TargetPath=$powershell; $lnk.Arguments="-NoExit -ExecutionPolicy Bypass -File `"$(Join-Path $install 'installer\start_login.ps1')`""; $lnk.WorkingDirectory=$install; $lnk.Save()
  $lnk=$shell.CreateShortcut((Join-Path $menu 'Abrir painel local.lnk')); $lnk.TargetPath='http://127.0.0.1:8765'; $lnk.Save()
  $desktop=[Environment]::GetFolderPath('Desktop'); $lnk=$shell.CreateShortcut((Join-Path $desktop 'Comprovei App.lnk')); $lnk.TargetPath=$powershell; $lnk.Arguments="-NoExit -ExecutionPolicy Bypass -File `"$(Join-Path $install 'start_app.ps1')`""; $lnk.WorkingDirectory=$install; $lnk.Save()
  Say 'Instalação concluída.'
  Write-Host 'Abra “1 - Fazer login no Comprovei” no menu Iniciar, entre manualmente e depois inicie o app.' -ForegroundColor Yellow
  Write-Host "Arquivos: $install`nDados locais: $state`nLog: $log"
  Stop-Transcript | Out-Null
  exit 0
}catch{
  $message=$_.Exception.Message
  Write-Host "`nFalha na instalação: $message" -ForegroundColor Red
  Write-Host "O instalador pode ser executado novamente. Log completo: $log" -ForegroundColor Yellow
  try{Stop-Transcript | Out-Null}catch{}
  exit 1
}
