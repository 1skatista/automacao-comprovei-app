$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form=New-Object System.Windows.Forms.Form
$form.Text='Instalar Comprovei App'; $form.StartPosition='CenterScreen'; $form.Size=New-Object System.Drawing.Size(620,330); $form.MinimumSize=New-Object System.Drawing.Size(620,330); $form.MaximizeBox=$false
$label=New-Object System.Windows.Forms.Label; $label.Text='Escolha onde instalar o Comprovei App'; $label.Location=New-Object Drawing.Point(24,22); $label.Size=New-Object Drawing.Size(540,28); $label.Font=New-Object Drawing.Font('Segoe UI',13,[Drawing.FontStyle]::Bold); $form.Controls.Add($label)
$hint=New-Object System.Windows.Forms.Label; $hint.Text='Os dados de sessão e configurações ficam na sua pasta de usuário do Windows.'; $hint.Location=New-Object Drawing.Point(26,58); $hint.Size=New-Object Drawing.Size(550,25); $hint.Font=New-Object Drawing.Font('Segoe UI',9); $form.Controls.Add($hint)
$pathBox=New-Object System.Windows.Forms.TextBox; $pathBox.Location=New-Object Drawing.Point(27,103); $pathBox.Size=New-Object Drawing.Size(435,27); $pathBox.Text=Join-Path $env:LOCALAPPDATA 'Programs\ComproveiApp'; $pathBox.Font=New-Object Drawing.Font('Segoe UI',10); $form.Controls.Add($pathBox)
$browse=New-Object System.Windows.Forms.Button; $browse.Text='Procurar...'; $browse.Location=New-Object Drawing.Point(472,101); $browse.Size=New-Object Drawing.Size(104,30); $form.Controls.Add($browse)
$status=New-Object System.Windows.Forms.Label; $status.Text='Clique em Prosseguir para instalar.'; $status.Location=New-Object Drawing.Point(28,150); $status.Size=New-Object Drawing.Size(550,25); $status.Font=New-Object Drawing.Font('Segoe UI',9); $form.Controls.Add($status)
$progress=New-Object System.Windows.Forms.ProgressBar; $progress.Location=New-Object Drawing.Point(28,180); $progress.Size=New-Object Drawing.Size(548,17); $progress.Style='Marquee'; $progress.MarqueeAnimationSpeed=25; $progress.Visible=$false; $form.Controls.Add($progress)
$logBox=New-Object System.Windows.Forms.TextBox; $logBox.Location=New-Object Drawing.Point(28,205); $logBox.Size=New-Object Drawing.Size(548,42); $logBox.Multiline=$true; $logBox.ReadOnly=$true; $logBox.BorderStyle='None'; $logBox.BackColor=$form.BackColor; $logBox.Font=New-Object Drawing.Font('Segoe UI',8); $form.Controls.Add($logBox)
$go=New-Object System.Windows.Forms.Button; $go.Text='Prosseguir'; $go.Location=New-Object Drawing.Point(450,255); $go.Size=New-Object Drawing.Size(126,34); $go.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold); $form.Controls.Add($go)
$cancel=New-Object System.Windows.Forms.Button; $cancel.Text='Cancelar'; $cancel.Location=New-Object Drawing.Point(318,255); $cancel.Size=New-Object Drawing.Size(120,34); $form.Controls.Add($cancel)
$dialog=New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description='Selecione a pasta onde deseja instalar o Comprovei App'; $dialog.ShowNewFolderButton=$true
$script:proc=$null; $script:timer=New-Object System.Windows.Forms.Timer; $script:timer.Interval=700
$browse.Add_Click({$dialog.SelectedPath=$pathBox.Text;if($dialog.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK){$pathBox.Text=$dialog.SelectedPath}})
$cancel.Add_Click({if($script:proc -and -not $script:proc.HasExited){[Windows.Forms.MessageBox]::Show('A instalação está em andamento. Aguarde a conclusão ou feche esta janela para interromper.','Instalação em andamento')|Out-Null}else{$form.Close()}})
$go.Add_Click({
  try {
    $target=[IO.Path]::GetFullPath($pathBox.Text.Trim())
    if([string]::IsNullOrWhiteSpace($pathBox.Text)){throw 'Informe a pasta de instalação.'}
    $pathBox.Text=$target; $go.Enabled=$false; $browse.Enabled=$false; $cancel.Text='Fechar'; $progress.Visible=$true; $status.Text='Instalando... isso pode levar alguns minutos.'
    $state=Join-Path $env:LOCALAPPDATA 'ComproveiApp'; New-Item -ItemType Directory -Force -Path $state|Out-Null
    $log=Join-Path $state 'installer.log'; Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
    $ps=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $scriptPath=Join-Path $PSScriptRoot 'Install.ps1'
    $quotedTarget=$target.Replace('"','`"'); $quotedScript=$scriptPath.Replace('"','`"')
    $start=New-Object Diagnostics.ProcessStartInfo; $start.FileName=$ps; $start.Arguments="-NoProfile -ExecutionPolicy Bypass -File `"$quotedScript`" -InstallRoot `"$quotedTarget`""; $start.WorkingDirectory=$PSScriptRoot; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $script:proc=[Diagnostics.Process]::Start($start); $script:timer.Start()
  }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Não foi possível iniciar a instalação',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error)|Out-Null; $go.Enabled=$true; $browse.Enabled=$true}
})
$timer.Add_Tick({
  $state=Join-Path $env:LOCALAPPDATA 'ComproveiApp'; $log=Join-Path $state 'installer.log'
  if(Test-Path -LiteralPath $log){try{$lines=Get-Content -LiteralPath $log -Tail 3 -ErrorAction Stop; if($lines.Count){$logBox.Text=($lines -join ' ')}}catch{}}
  if($script:proc -and $script:proc.HasExited){$script:timer.Stop(); $script:proc.Refresh(); $progress.Visible=$false; $browse.Enabled=$true
    if($script:proc.ExitCode -eq 0){$status.Text='Instalação concluída.'; $logBox.Text='Atalhos criados no menu Iniciar e na área de trabalho.'; $go.Text='Concluído'; $go.Enabled=$false; $cancel.Text='Fechar'; [Windows.Forms.MessageBox]::Show("Instalação concluída em:`n$($pathBox.Text)`n`nAbra o atalho '1 - Fazer login no Comprovei' no menu Iniciar.",'Comprovei App instalado',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)|Out-Null}
    else{$errorText='Consulte o log para ver o motivo.'; if(Test-Path -LiteralPath $log){$content=Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue; if($content -match '(?m)^Falha na instalação:\s*(.+)$'){$errorText=$Matches[1].Trim()}}; $status.Text='A instalação falhou. Leia o erro e tente novamente.'; $go.Text='Tentar novamente'; $go.Enabled=$true; $logBox.Text=$errorText; [Windows.Forms.MessageBox]::Show("Falha na instalação: $errorText

A tela continuará aberta para você tentar novamente.
Log completo:
$log",'Falha na instalação',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error)|Out-Null; $script:proc=$null}
  }
})
[void]$form.ShowDialog()

