// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

using UnrealBuildTool;
using System.Collections.Generic;

public class ArenaRunnerTarget : TargetRules
{
	public ArenaRunnerTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("ArenaRunner");
	}
}
