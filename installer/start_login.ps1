$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$python = Join-Path $project '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) { throw 'Ambiente Python não instalado. Execute novamente o instalador.' }
& $python (Join-Path $project 'login.py')
