// Copyright Melon Studios.

using UnrealBuildTool;

public class ATLA : ModuleRules
{
	public ATLA(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        // * Core dependencies
        PublicDependencyModuleNames.AddRange(["Core", "CoreUObject", "Engine", "InputCore", "EnhancedInput"]);
        
        // * Slate Dependencies
        PrivateDependencyModuleNames.AddRange(["Slate", "SlateCore"]);

		// * UI dependencies
		PublicDependencyModuleNames.AddRange(["UMG", "CommonUI", "ModelViewViewModel"]);
		
		// * Gameplay System dependencies
		PublicDependencyModuleNames.AddRange(["GameplayTags"]);
	}
}
