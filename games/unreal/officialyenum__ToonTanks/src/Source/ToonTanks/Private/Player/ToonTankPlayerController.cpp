// Fill out your copyright notice in the Description page of Project Settings.


#include "Player/ToonTankPlayerController.h"

void AToonTankPlayerController::SetPlayerEnabledState(bool bPlayerEnabled)
{
	if(bPlayerEnabled)
	{
		GetPawn()->EnableInput(this);
	}
	else
	{
		GetPawn()->DisableInput(this);
	}
	bShowMouseCursor = bPlayerEnabled;
}
