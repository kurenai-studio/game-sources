// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "Enum/EPushSoftWidgetAsyncState.h"

#include "ATLAUIGameInstanceSubsystem.generated.h"

class UATLACommonButtonBase;
class UATLACommonActivatableWidget;
struct FGameplayTag;
class UATLACommonUserWidget;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnButtonDescriptionTextUpdatedDelegate, UATLACommonButtonBase*, BroadcastingButton, FText, DescriptionText);

/**
 *	ATLA UI Game Instance Subsystem Class.
 */
UCLASS()
class ATLA_API UATLAUIGameInstanceSubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	static UATLAUIGameInstanceSubsystem* Get(const UObject* WorldContextObject);

	//~ Begin USubsystem Interface
	virtual bool ShouldCreateSubsystem(UObject* Outer) const override;
	//~ End USubsystem Interface

	UFUNCTION(BlueprintCallable, Category = "ATLA|UI")
	void RegisterCreatedATLACommonUserWidget(UATLACommonUserWidget* InCreatedWidget);

	void PushSoftWidgetToStackAsync(const FGameplayTag& InWidgetStackTag, TSoftClassPtr<UATLACommonActivatableWidget> InSoftWidgetClass,
	                                TFunction<void(EPushSoftWidgetAsyncState, UATLACommonActivatableWidget*)> AsyncPushStateCallback);
	
	UPROPERTY(BlueprintAssignable, Category = "ATLA|UI")
	FOnButtonDescriptionTextUpdatedDelegate OnButtonDescriptionTextUpdated;

private:
	UPROPERTY(Transient)
	UATLACommonUserWidget* CreatedATLACommonUserWidget;
};
