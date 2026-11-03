using UnrealBuildTool;
using System.Collections.Generic;

public class PingPongTarget : TargetRules
{
	public PingPongTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("PingPong");
	}
}
