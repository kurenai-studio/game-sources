// Fill out your copyright notice in the Description page of Project Settings.


#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

// Called when the game starts or when spawned
void ATower::BeginPlay()
{
	Super::BeginPlay();

    Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));

    // Creates a looping timer to trigger fire
    GetWorldTimerManager().SetTimer(
        FireRateTimerHandle, 
        this, 
        &ATower::CheckFireCondition, 
        FireRate, 
        true
    );

    
}

void ATower::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    if (IsTankInRange())
    {
        RotateTurret(Tank->GetActorLocation());
    }
}

void ATower::HandleDestruction()
{
    Super::HandleDestruction();
    Destroy();
}

void ATower::CheckFireCondition()
{
    if (Tank && Tank->bAlive && IsTankInRange())
    {
        Fire();
    }
}

bool ATower::IsTankInRange()
{
    if (!Tank)
    {
        return false;
    }

    // find distance to the Tank
    float Distance = FVector::Dist(GetActorLocation(), Tank->GetActorLocation());

    // check if the tank is in range
    return (Distance <= FireRange);
}