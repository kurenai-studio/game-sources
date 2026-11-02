// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

using UnrealBuildTool;
using System.Collections.Generic;

public class ArenaRunnerEditorTarget : TargetRules
{
	public ArenaRunnerEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("ArenaRunner");
	}
}
