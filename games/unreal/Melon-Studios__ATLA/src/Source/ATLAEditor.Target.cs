// Copyright Melon Studios.

using UnrealBuildTool;
using System.Collections.Generic;

public class ATLAEditorTarget : TargetRules
{
	public ATLAEditorTarget( TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("ATLA");
	}
}
