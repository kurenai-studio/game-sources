// Fill out your copyright notice in the Description page of Project Settings.


#include "SuperSoldier/Controllers/SuperSoldierPlayerController.h"
#include "Blueprint/UserWidget.h"

void ASuperSoldierPlayerController::BeginPlay() 
{
    Super::BeginPlay();
    if (HUDClass == NULL)
    {
        return;
    }
    HUD = CreateWidget(this, HUDClass);

    if (HUD)
    {
        HUD->AddToViewport();
    }
}

float ASuperSoldierPlayerController::GetRestartDelay() const
{
    return RestartDelay;
}

void ASuperSoldierPlayerController::RestartCurrentLevel() 
{
    RestartLevel();
}

void ASuperSoldierPlayerController::GameHasEnded(class AActor* EndGameFocus, bool bIsWinner) 
{
    Super::GameHasEnded(EndGameFocus, bIsWinner);

    HUD->RemoveFromViewport();

    HandleEndGameScreen(bIsWinner);
}
