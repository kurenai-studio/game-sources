// Fill out your copyright notice in the Description page of Project Settings.


#include "Turret.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

void ATurret::BeginPlay()
{
	Super::BeginPlay();

	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));

	InitialRotator = GetActorRotation();

	GetWorldTimerManager().SetTimer(FireRateTimerHandle, this, &ATurret::CheckFireCondition, FireRate, true);
}

void ATurret::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);


	if (IsInRange())
	{
		RotateTurret(Tank->GetActorLocation());
	}
	else
	{
		RotateTurret(InitialRotator);
	}
}

void ATurret::HandleDestruction()
{
	Super::HandleDestruction();
	Destroy();
}

void ATurret::CheckFireCondition()
{
	if (IsInRange())
	{
		Fire();
	}
}

bool ATurret::IsInRange()
{
	if (!Tank)
		return false;
	else if (!Tank->bAlive)
		return false;

	return FVector::Dist(GetActorLocation(), Tank->GetActorLocation()) <= Range;
}
