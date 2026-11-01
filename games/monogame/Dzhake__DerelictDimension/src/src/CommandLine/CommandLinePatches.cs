using HarmonyLib;

namespace DerelictDimension.CommandLine;

/// <summary>
/// <see cref="Harmony"/> patches for <see cref="System.CommandLine"/>.
/// </summary>
[HarmonyPatch]
internal class CommandLinePatches
{
    /// <summary>
    /// Prevent helper builder from printing "Description" section, as it makes no sense for game.
    /// </summary>
    [HarmonyPatch]
    private static bool HelpBuilder_Default_SynopsisSection() => false;
}
