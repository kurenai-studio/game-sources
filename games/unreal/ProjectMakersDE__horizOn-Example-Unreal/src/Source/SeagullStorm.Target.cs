using UnrealBuildTool;

public class SeagullStormTarget : TargetRules
{
    public SeagullStormTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("SeagullStorm");
    }
}
