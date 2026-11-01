using UnrealBuildTool;

public class SeagullStormEditorTarget : TargetRules
{
    public SeagullStormEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("SeagullStorm");
    }
}
