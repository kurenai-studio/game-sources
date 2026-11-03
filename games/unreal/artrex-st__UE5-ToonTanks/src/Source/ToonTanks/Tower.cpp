// Fill out your copyright notice in the Description page of Project Settings.


#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

void ATower::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (InFireRange())
	{
		RotateTurret(Tank->GetActorLocation());	
	}
}

void ATower::HandlerDestruction()
{
	Super::HandlerDestruction();
	Destroy();
}

void ATower::BeginPlay()
{
	Super::BeginPlay();
	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	const float RandomDelay = FMath::FRandRange(-0.5f * FireRate, 0.5f * FireRate);
	
	GetWorldTimerManager().SetTimer(FireRateTimerHandler, this, &ATower::CheckFireCondition, FireRate + RandomDelay, true);
}

void ATower::CheckFireCondition()
{
	if (InFireRange() && TargetLock())
	{
		Fire();
	}
}

bool ATower::TargetLock() const
{
	FVector StartLocation = GetProjectileSpawnPoint()->GetComponentLocation();
	FVector ForwardVector = GetProjectileSpawnPoint()->GetComponentRotation().Vector();
	FVector EndLocation = StartLocation + (ForwardVector * FireRange);

	FHitResult HitResult;

	FCollisionQueryParams CollisionParams;
	CollisionParams.AddIgnoredActor(this);

	GetWorld()->LineTraceSingleByChannel(HitResult, StartLocation, EndLocation, ECC_Visibility, CollisionParams);
	//DrawDebugLine(GetWorld(), StartLocation, EndLocation, FColor::Green, false);

	if (HitResult.bBlockingHit)
	{
		AActor* HitActor = HitResult.GetActor();
		return HitActor == Tank;
	}

	return false;
}

bool ATower::InFireRange() const
{
	return Tank->bAlive && Tank && FVector::Dist(GetActorLocation(),Tank->GetActorLocation()) <= FireRange;
}
