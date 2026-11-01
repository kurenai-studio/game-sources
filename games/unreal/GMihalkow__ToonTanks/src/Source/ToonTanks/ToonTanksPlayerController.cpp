// Fill out your copyright notice in the Description page of Project Settings.

#include "ToonTanksPlayerController.h"
#include "GameFramework/Pawn.h"

void AToonTanksPlayerController::BeginPlay()
{
	Super::BeginPlay();
}

void AToonTanksPlayerController::ToggleEnabledInputState(bool enabled)
{
	if (enabled)
	{
		this->GetPawn()->EnableInput(this);
	}
	else
	{
		this->GetPawn()->DisableInput(this);
	}

	this->bShowMouseCursor = enabled;
}