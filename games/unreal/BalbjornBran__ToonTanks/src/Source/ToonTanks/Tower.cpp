// Created by Balbjorn Bran.


#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

void ATower::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (InFireRange())
	{
		RotateTurret(Tank_Ref->GetActorLocation());
	}	
}

void ATower::HandleDestruction()
{
	Super::HandleDestruction();
	Destroy();
}

void ATower::BeginPlay()
{
	Super::BeginPlay();
	Tank_Ref = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this,0));

	GetWorldTimerManager().SetTimer(FireTimerHandle, this, &ATower::checkFireCondition, FireRate, true);
	
}

void ATower::checkFireCondition()
{
	if (Tank_Ref == nullptr)
	{
		return;
	}
	if (InFireRange() && Tank_Ref->bIsAlive)
	{
		Fire();
	}
}

bool ATower::InFireRange()
{
	float Distance = FVector::Dist(Tank_Ref->GetActorLocation(), GetActorLocation());
		if (Distance <= FireRange)
		{
			return true;
		}
	return false;
}
