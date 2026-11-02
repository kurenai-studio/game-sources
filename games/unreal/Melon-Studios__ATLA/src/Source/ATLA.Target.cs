// Copyright Melon Studios.

using UnrealBuildTool;
using System.Collections.Generic;

public class ATLATarget : TargetRules
{
	public ATLATarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("ATLA");
	}
}
