// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Animation/WidgetAnimation.h"

#include "StartScreen.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnFadeOutComplete);

UCLASS()
class BATTLEBLASTER_API UStartScreen : public UUserWidget
{
	GENERATED_BODY()

public:
	UPROPERTY(Transient, meta = (BindWidgetAnim))
	UWidgetAnimation* FadeOutAnim;

	UPROPERTY(BlueprintAssignable)
	FOnFadeOutComplete OnFadeOutComplete;

	void PlayFadeOut();

protected:
	virtual void NativeConstruct() override;

private:
	UFUNCTION()
	void HandleFadeOutFinished();
};