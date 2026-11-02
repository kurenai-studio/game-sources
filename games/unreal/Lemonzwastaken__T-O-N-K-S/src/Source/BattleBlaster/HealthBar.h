// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Components/ProgressBar.h"


#include "HealthBar.generated.h"

/**
 * 
 */
UCLASS()
class BATTLEBLASTER_API UHealthBar : public UUserWidget
{
	GENERATED_BODY()
	
public:

	UPROPERTY(EditAnywhere, meta = (BindWidget))
	UProgressBar* HealthProgressBar;

	void SetHealthPercent(float Percent);


};
