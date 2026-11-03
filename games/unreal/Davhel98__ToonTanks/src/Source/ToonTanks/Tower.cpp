// Fill out your copyright notice in the Description page of Project Settings.


#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"

void ATower::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if(CheckIfTankIsInRange())
	{
		RotateTurret(Tank->GetActorLocation());
	}
}

void ATower::BeginPlay()
{
	Super::BeginPlay();

	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));

	GetWorldTimerManager().SetTimer(FireRateTimerHandle, this, &ATower::CheckFireCondition, FireRate, true);
}

void ATower::CheckFireCondition()
{
	if(CheckIfTankIsInRange())
	{
		Fire();
	}
}

bool ATower::CheckIfTankIsInRange() const
{
	if(Tank)
	{
		//Find distance to the Tank
		const float Distance = FVector::Dist(GetActorLocation(), Tank->GetActorLocation());
		//Check if Tank is in Range and is alive
		return Distance <= FireRange && Tank->bIsAlive;
	}
	return false;
}

void ATower::HandleDestruction()
{
	Super::HandleDestruction();
	Destroy();
}