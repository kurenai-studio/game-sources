// Fill out your copyright notice in the Description page of Project Settings.

#include "StartScreen.h"

void UStartScreen::NativeConstruct()
{
	Super::NativeConstruct();

	if (FadeOutAnim)
	{
		FWidgetAnimationDynamicEvent FinishedDelegate;
		FinishedDelegate.BindDynamic(this, &UStartScreen::HandleFadeOutFinished);
		BindToAnimationFinished(FadeOutAnim, FinishedDelegate);
	}
}

void UStartScreen::PlayFadeOut()
{
	if (FadeOutAnim)
	{
		PlayAnimation(FadeOutAnim);
	}
}

void UStartScreen::HandleFadeOutFinished()
{
	OnFadeOutComplete.Broadcast();
	RemoveFromParent();
}