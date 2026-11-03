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

	GetWorldTimerManager().SetTimer(FireRateTimerHandle, this, &ATower::CheckFireCondition, FireRate, true);
}

//Check if in fire range
bool ATower::InFireRange()
{
	if (Tank)
	{
		//Find distance to the tank
		float Distance = FVector::Dist(GetActorLocation(), Tank->GetActorLocation());
		//check to see if the tank is range
		if (Distance <= FireRange)
		{
			return true;
		}
	}
	return false;
}

//Tower can fire to player
void ATower::CheckFireCondition()
{
	if (Tank == nullptr)
	{
		return;
	}
	if (InFireRange() && Tank->bAlive)
	{
		RotateTurret(Tank->GetActorLocation());
		Fire();
	}
}


void ATower::HandleDestruction()
{
	Super::HandleDestruction();

	Destroy();
}

// Called every frame
void ATower::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (InFireRange())
	{
		RotateTurret(Tank->GetActorLocation());
	}
}