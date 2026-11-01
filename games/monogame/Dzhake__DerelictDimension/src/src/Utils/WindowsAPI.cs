using System.Runtime.InteropServices;
using System.Runtime.Versioning;

namespace DerelictDimension;


/// <summary>
/// Class for native windows API calls using <see cref="LibraryImportAttribute"/>
/// </summary>
[SupportedOSPlatform("windows")]
public static partial class WindowsAPI
{
    /// <summary>
    /// Allocates a new console for the calling process.
    /// </summary>
    /// <returns>If the function succeeds, the return value is nonzero (true). If the function fails, the return value is zero (false). To get extended error information, call GetLastError.</returns>
    [LibraryImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static partial bool AllocConsole();

    /// <summary>
    /// Whether <see cref="AllocConsoleSafe"/> was called.
    /// </summary>
    public static bool ConsoleAllocated;

    /// <summary>
    /// Allocates a new console for the calling process, but only if <see cref="ConsoleAllocated"/> is false.
    /// </summary>
    /// <returns>False if console was already allocated, otherwise: if the function succeeds, the return value is nonzero (true). If the function fails, the return value is zero (false).</returns>
    public static bool AllocConsoleSafe()
    {
        if (ConsoleAllocated) return false;
        ConsoleAllocated = true;
        return AllocConsole();
    }
}
