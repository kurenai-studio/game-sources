// Fill out your copyright notice in the Description page of Project Settings.


#include "Character/Tower.h"
#include "TimerManager.h"
#include "Character/Tank.h"
#include "Kismet/GameplayStatics.h"


// Sets default values
ATower::ATower()
{
	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
}

// Called when the game starts or when spawned
void ATower::BeginPlay()
{
	Super::BeginPlay();
	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	FireRate = FMath::RandRange(FireRate, MaxFireRate);
	GetWorldTimerManager().SetTimer(FireRateTimerHandle, this, &ATower::CheckFireCondition, FireRate, true);
}

// Called every frame
void ATower::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (InFireRange()){
		// if in range, rotate turret toward tank
		RotateTurret(Tank->GetActorLocation());
	}
}


// Called to bind functionality to input
void ATower::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
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
	if (InFireRange() && Tank->bAlive){
		// if in range, fire
		Fire();
	}
}

bool ATower::InFireRange() const
{
	if (Tank)
	{
		// find the distance to the tank
		float Distance = FVector::Dist(GetActorLocation(), Tank->GetActorLocation());
		// check to see if the tank is in range
		if (Distance <= FireRange)
		{
			return true;
		}
	}
	return false;
}

