// Fill out your copyright notice in the Description page of Project Settings.


#include "Toon_Tank_GameModeBase.h"
#include "Toon_Tanks/Pawns/PawnTank.h"
#include "Toon_Tanks/Pawns/PawnTurret.h"
#include "Kismet/GameplayStatics.h"
#include "Toon_Tanks/PlayerControllers/PlayerControllerBase.h"

#define OUT

void AToon_Tank_GameModeBase::BeginPlay() 
{
    Super::BeginPlay();

    HandleGameStart();
}

void AToon_Tank_GameModeBase::ActorDied(AActor* DeadActor) 
{
    if (DeadActor == PlayerTank)
    {
        PlayerTank->HandleDestruction();
        HandleGameOver(false);

        if (PlayerControllerRef)
        {
            PlayerControllerRef->SetPlayerEnabledState(false);
        }
    }
    else if (APawnTurret* DestroyedTurret = Cast<APawnTurret>(DeadActor))
    {
        DestroyedTurret->HandleDestruction();

        if(--TargetTurrets == 0)
        {
            HandleGameOver(true);
        }
    }
}

void AToon_Tank_GameModeBase::HandleGameStart() 
{
    TargetTurrets = GetTargetTurretCount();
    PlayerTank = Cast<APawnTank>(UGameplayStatics::GetPlayerPawn(this, 0));
    PlayerControllerRef = Cast<APlayerControllerBase>(UGameplayStatics::GetPlayerController(this, 0));
    GameStart();
    if (PlayerControllerRef)
    {
        PlayerControllerRef->SetPlayerEnabledState(false);

        FTimerHandle PlayerEnableHandle;
        FTimerDelegate PlayerEnableDelegate = FTimerDelegate::CreateUObject(PlayerControllerRef,
        &APlayerControllerBase::SetPlayerEnabledState, true);

        GetWorld()->GetTimerManager().SetTimer(PlayerEnableHandle, PlayerEnableDelegate, StartDelay, false);
    }
}

void AToon_Tank_GameModeBase::HandleGameOver(bool PlayerWon) 
{
    GameOver(PlayerWon);
}


int32 AToon_Tank_GameModeBase::GetTargetTurretCount() 
{
    TArray<AActor*> TurretActors;
    UGameplayStatics::GetAllActorsOfClass(GetWorld(), APawnTurret::StaticClass(), OUT TurretActors);
    return TurretActors.Num();
}
