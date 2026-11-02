// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "Kismet/BlueprintFunctionLibrary.h"

#include "ATLAUIBlueprintFunctionLibrary.generated.h"

class UATLACommonActivatableWidget;

/**
 *	ATLA UI Blueprint Function Library Class.
 */
UCLASS()
class ATLA_API UATLAUIBlueprintFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, BlueprintPure, Category = "ATLA|UI|Widget")
	static TSoftClassPtr<UATLACommonActivatableWidget> GetWidgetSoftClassByTag(UPARAM(meta = (Categories = "ATLA.UI.Widget")) const FGameplayTag InWidgetTag);
};
