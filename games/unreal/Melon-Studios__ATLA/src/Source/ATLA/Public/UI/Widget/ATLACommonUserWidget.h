// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "CommonUserWidget.h"
#include "GameplayTagContainer.h"

#include "ATLACommonUserWidget.generated.h"

class UCommonActivatableWidgetContainerBase;

/**
 *	ATLA Common User Widget Class.
 */
UCLASS(Abstract, BlueprintType, meta = (DisableNativeTick))
class ATLA_API UATLACommonUserWidget : public UCommonUserWidget
{
	GENERATED_BODY()

public:
	UCommonActivatableWidgetContainerBase* GetWidgetStackByTag(const FGameplayTag& InTag) const;

protected:
	UFUNCTION(BlueprintCallable, Category = "ATLA|UI")
	void CreateWidgetStack(UPARAM(meta = ( Categories = "ATLA.UI.Layer")) const FGameplayTag InStackTag, UCommonActivatableWidgetContainerBase* InStack);

private:
	UPROPERTY(Transient)
	TMap<FGameplayTag, UCommonActivatableWidgetContainerBase*> WidgetStackMap;
};
