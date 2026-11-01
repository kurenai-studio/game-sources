// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include <Components/TextBlock.h>

#include "PlayerHUD.generated.h"

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API UPlayerHUD : public UUserWidget
{
	GENERATED_BODY()
	
public:
	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* HealthText;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* CoinsText;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* DiamondsText;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* KeysText;

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UTextBlock* SwordsText;

	UFUNCTION(BlueprintCallable)
	void setPlayerInfo(int health, int coins, int diamonds, int keys, int swords);
};
