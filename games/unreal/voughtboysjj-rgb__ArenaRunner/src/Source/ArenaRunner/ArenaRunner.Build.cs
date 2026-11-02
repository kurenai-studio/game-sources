// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

using UnrealBuildTool;

public class ArenaRunner : ModuleRules
{
	public ArenaRunner(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicDependencyModuleNames.AddRange(new string[]
		{
			"Core",
			"CoreUObject",
			"Engine",
			"InputCore"
		});

		PrivateDependencyModuleNames.AddRange(new string[]
		{
		});
	}
}
