// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include <Components/ProgressBar.h>

#include "EnemyHealthBar.generated.h"

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API UEnemyHealthBar : public UUserWidget
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UProgressBar* HealthBar;

	UFUNCTION(BlueprintCallable)
	void SetHealth(float newHealth, float maxHealth);
};
