$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$python = Join-Path $project '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) { throw 'Ambiente Python não instalado. Execute novamente o instalador.' }
if (-not (Test-Path (Join-Path $project 'config.json'))) { throw 'Configuração ausente. Execute novamente o instalador.' }
$state = Join-Path $env:LOCALAPPDATA 'ComproveiApp'
New-Item -ItemType Directory -Force -Path $state | Out-Null
$tokenFile = Join-Path $state 'app-token.dpapi'
if (-not (Test-Path $tokenFile)) {
  $bytes = New-Object byte[] 32
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
  $token = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
  $secure = ConvertTo-SecureString -String $token -AsPlainText -Force
  ConvertFrom-SecureString -SecureString $secure | Set-Content -Encoding ASCII -Path $tokenFile
} else {
  $secure = Get-Content -Raw -Path $tokenFile | ConvertTo-SecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}
$env:COMPROVEI_APP_TOKEN = $token
Write-Host 'Token do app (cole no navegador):' -ForegroundColor Yellow
Write-Host $token -ForegroundColor Cyan
Write-Host 'Servidor local: http://127.0.0.1:8765' -ForegroundColor Green
Write-Host 'Deixe esta janela aberta enquanto usa o app. Ctrl+C encerra o servidor.'
& $python (Join-Path $project 'app_server.py')
