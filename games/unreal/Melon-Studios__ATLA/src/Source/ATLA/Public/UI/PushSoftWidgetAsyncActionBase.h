// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintAsyncActionBase.h"
#include "GameplayTagContainer.h"

#include "PushSoftWidgetAsyncActionBase.generated.h"

class UATLACommonActivatableWidget;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnPushSoftWidgetDelegate, UATLACommonActivatableWidget*, PushedWidget);

/**
 *	ATLA Common UI Push Soft Widget Async Action Base Class.
 */
UCLASS()
class ATLA_API UPushSoftWidgetAsyncActionBase : public UBlueprintAsyncActionBase
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "ATLA|UI|Widget", meta = (WorldContext = "WorldContextObject", HidePin = "WorldContextObject", BlueprintInternalUseOnly = "true"),
		DisplayName = "Push Soft Widget To Widget Stack")
	static UPushSoftWidgetAsyncActionBase* PushSoftWidget(const UObject* WorldContextObject, APlayerController* OwningPlayerController,
	                                                      TSoftClassPtr<UATLACommonActivatableWidget> InSoftWidgetClass,
	                                                      UPARAM(meta = ( Categories = "ATLA.UI.Layer")) FGameplayTag InWidgetStackTag,
	                                                      bool bFocusOnNewlyPushedWidget = true);

	//~ Begin UBlueprintAsyncActionBase Interface
	virtual void Activate() override;
	//~ End UBlueprintAsyncActionBase Interface
	
	UPROPERTY(BlueprintAssignable)
	FOnPushSoftWidgetDelegate OnPushSoftWidgetStart;

	UPROPERTY(BlueprintAssignable)
	FOnPushSoftWidgetDelegate OnPushSoftWidgetEnd;

private:
	TWeakObjectPtr<UWorld> CachedOwningWorld;
	TWeakObjectPtr<APlayerController> CachedOwningPC;
	TSoftClassPtr<UATLACommonActivatableWidget> CachedSoftWidgetClass;
	FGameplayTag CachedWidgetStackTag;
	bool bCachedFocusOnNewlyPushedWidget = false;
};
