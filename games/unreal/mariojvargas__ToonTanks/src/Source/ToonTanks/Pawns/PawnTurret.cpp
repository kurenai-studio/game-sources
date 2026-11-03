// Fill out your copyright notice in the Description page of Project Settings.


#include "PawnTurret.h"
#include "PawnTank.h"
#include "Kismet/GameplayStatics.h"

APawnTurret::APawnTurret()
{

}

// Called when the game starts or when spawned
void APawnTurret::BeginPlay()
{
	Super::BeginPlay();
	
    PlayerPawn = Cast<APawnTank>(UGameplayStatics::GetPlayerPawn(this, 0));

    const bool bLoopTimer = true;
    GetWorld()->GetTimerManager().SetTimer(FireRateTimerHandle, this, &APawnTurret::CheckFireCondition, FireRate, bLoopTimer);
}

void APawnTurret::HandleDestruction() 
{
    Super::HandleDestruction();

    Destroy();
}

// Called every frame
void APawnTurret::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

    if (!PlayerPawn || GetDistanceToPlayer() > FireRange)
    {
        return;
    }

    RotateTurretTowardsTarget(PlayerPawn->GetActorLocation());
}


void APawnTurret::CheckFireCondition() 
{
    // If player == null || is dead then bail!
    if (!(PlayerPawn && PlayerPawn->GetIsPlayerAlive()))
    {
        return;
    }

    // If player is in range then fire!
    if (GetDistanceToPlayer() <= FireRange)
    {
        Fire();
    }

}

float APawnTurret::GetDistanceToPlayer() const
{
    if (!PlayerPawn)
    {
        return 0.f;
    }

    // This also works -> GetDistanceTo(PlayerPawn); 
    return FVector::Dist(PlayerPawn->GetActorLocation(), GetActorLocation());
}