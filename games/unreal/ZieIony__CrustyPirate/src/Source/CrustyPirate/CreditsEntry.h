// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include <Components/TextBlock.h>

#include "CreditsEntry.generated.h"

/**
 *
 */
UCLASS()
class CRUSTYPIRATE_API UCreditsEntry: public UUserWidget {
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* LabelText;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* ValueText;

	void setLabel(const FString& label);
	void setValue(const FString& value);
};
