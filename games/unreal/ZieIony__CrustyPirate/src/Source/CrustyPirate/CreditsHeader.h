// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include <Components/TextBlock.h>

#include "CreditsHeader.generated.h"

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API UCreditsHeader : public UUserWidget
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* LabelText;

	void setLabel(const FString& label);
};
