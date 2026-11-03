// Fill out your copyright notice in the Description page of Project Settings.


#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

ATower::ATower()
{

}

void ATower::BeginPlay()
{
    Super::BeginPlay();

    Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));

    GetWorldTimerManager().SetTimer(FireTimerHandle, this, &ATower::CheckFireCondition, FireRate, true);
}

void ATower::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    if (InFireRange())
    {
        // If in range, rotate turret toward Tank
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
    if (Tank == nullptr) 
    {
        return;
    }
    
    if (InFireRange() && Tank->bAlive)
    {
        // If in range, the turret fires
        Fire();
    }
}

bool ATower::InFireRange()
{
    if (Tank)
    {
        // Find the distance to the Tank
        float Distance = FVector::Dist(GetActorLocation(), Tank->GetActorLocation());

        // Check to see if the Tank is in range
        if (Distance <= FireRange)
        {
            // If in range return true
            return true;
        }
    }

    return false;
}
