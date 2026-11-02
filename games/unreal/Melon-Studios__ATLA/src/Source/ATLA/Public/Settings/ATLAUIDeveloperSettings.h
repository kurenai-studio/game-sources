// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "Engine/DeveloperSettings.h"

#include "ATLAUIDeveloperSettings.generated.h"

class UATLACommonActivatableWidget;

/**
 *	ATLA UI Developer Settings Class.
 */
UCLASS(Config = Game, DefaultConfig, meta = (DisplayName = "ATLA Settings"))
class ATLA_API UATLAUIDeveloperSettings : public UDeveloperSettings
{
	GENERATED_BODY()

public:
	UPROPERTY(Config, EditAnywhere, Category = "Widget Reference", meta = (Categories = "ATLA.UI.Widget"))
	TMap<FGameplayTag, TSoftClassPtr<UATLACommonActivatableWidget>> ATLAUIWidgetMap;
};
