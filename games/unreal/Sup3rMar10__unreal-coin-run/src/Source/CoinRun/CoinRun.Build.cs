using UnrealBuildTool;

public class CoinRun : ModuleRules
{
	public CoinRun(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicDependencyModuleNames.AddRange(new string[] { "Core", "CoreUObject", "Engine", "InputCore" });

		// Lets the sources include "Rules/Foo.h" and "Game/Foo.h" relative to the module directory,
		// the same include root the plain C++ tests use (Tests/rules/CMakeLists.txt).
		PrivateIncludePaths.Add(ModuleDirectory);
	}
}
