// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Blueprint/UserWidget.h"
#include "CoreMinimal.h"
#include <Components/ScrollBox.h>
#include <Components/TextBlock.h>
#include <Components/VerticalBox.h>
#include <Engine/DataTable.h>
#include <Templates/SubclassOf.h>
#include "CreditsHeader.h"
#include "CreditsEntry.h"

#include "CreditsWidget.generated.h"

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API UCreditsWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float ScrollSpeed;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UScrollBox* ScrollBox;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UVerticalBox* VerticalBox;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	UDataTable* Data;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCreditsHeader> CreditsHeaderClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCreditsEntry> CreditsEntryClass;

	virtual void NativeConstruct() override;

	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime)override;
};
