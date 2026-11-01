// Fill out your copyright notice in the Description page of Project Settings.


#include "KillAllEnermiesGameMode.h"
#include "EngineUtils.h"
#include "SuperSoldier/AI/Controllers/SuperSoldierAIController.h"
#include "GameFramework/Controller.h"


void AKillAllEnermiesGameMode::PawnKilled(APawn* PawnKilled) 
{
    Super::PawnKilled(PawnKilled);

    APlayerController* PlayerController = Cast<APlayerController>(PawnKilled->GetController());
    if (PlayerController)
    {
        EndGame(false);
        return;
    }

    for (ASuperSoldierAIController* AIController : TActorRange<ASuperSoldierAIController>(GetWorld()))
    {
        if (!AIController->IsDead())
        {
            return;
        }
    }
    EndGame(true);
}

void AKillAllEnermiesGameMode::EndGame(bool bPlayerWin) 
{
    APlayerController* Controller = GetWorld()->GetFirstPlayerController();
    if (Controller)
    {
        Controller->GameHasEnded(Controller->GetPawn(), bPlayerWin);
    }
}
