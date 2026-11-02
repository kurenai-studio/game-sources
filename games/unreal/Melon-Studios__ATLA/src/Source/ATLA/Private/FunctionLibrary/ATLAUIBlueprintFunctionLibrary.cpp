// Copyright Melon Studios.

#include "FunctionLibrary/ATLAUIBlueprintFunctionLibrary.h"

#include "Settings/ATLAUIDeveloperSettings.h"

TSoftClassPtr<UATLACommonActivatableWidget> UATLAUIBlueprintFunctionLibrary::GetWidgetSoftClassByTag(const FGameplayTag InWidgetTag)
{
	const UATLAUIDeveloperSettings* ATLAUIDeveloperSettings = GetDefault<UATLAUIDeveloperSettings>();
	checkf(ATLAUIDeveloperSettings->ATLAUIWidgetMap.Contains(InWidgetTag), TEXT("GG : Error Get Widget Soft Class By Tag %s"), *InWidgetTag.ToString());

	return ATLAUIDeveloperSettings->ATLAUIWidgetMap.FindRef(InWidgetTag);
}
