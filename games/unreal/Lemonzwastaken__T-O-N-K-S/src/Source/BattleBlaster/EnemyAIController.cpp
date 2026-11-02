#include "EnemyAIController.h"
#include "EnemyTank.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "NavigationPath.h"
#include "NavigationSystem.h"

AEnemyAIController::AEnemyAIController()
{
}

void AEnemyAIController::RequestImmediateRepath()
{

	if (GetWorldTimerManager().GetTimerRemaining(RepathTimerHandle) > RepathInterval * 0.5f)
	{
		return;
	}

	ChasePlayer();

	GetWorldTimerManager().ClearTimer(RepathTimerHandle);
	GetWorldTimerManager().SetTimer(
		RepathTimerHandle,
		this,
		&AEnemyAIController::ChasePlayer,
		RepathInterval,
		true
	);
}

void AEnemyAIController::BeginPlay()
{
	Super::BeginPlay();

	// Each tank picks a random point around the player to approach,
	// instead of all pathing to the exact same spot
	const float RandomAngle = FMath::RandRange(0.0f, 360.0f);
	const float RandomRadius = FMath::RandRange(SurroundRadius * 0.5f, SurroundRadius);
	SurroundOffset = FVector(
		FMath::Cos(FMath::DegreesToRadians(RandomAngle)),
		FMath::Sin(FMath::DegreesToRadians(RandomAngle)),
		0.0f
	) * RandomRadius;

	const float RandomizedInterval =
		RepathInterval * FMath::RandRange(1.0f - RepathIntervalVariance, 1.0f + RepathIntervalVariance);
	const float InitialDelay = FMath::RandRange(0.0f, RandomizedInterval);

	GetWorldTimerManager().SetTimer(
		RepathTimerHandle,
		this,
		&AEnemyAIController::ChasePlayer,
		RandomizedInterval,
		true,
		InitialDelay
	);
}

void AEnemyAIController::ChasePlayer()
{
	AEnemyTank* EnemyTank = Cast<AEnemyTank>(GetPawn());
	ATank* PlayerTank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(GetWorld(), 0));

	if (!EnemyTank || !PlayerTank)
	{
		return;
	}

	EnemyTank->Tank = PlayerTank;

	// Slightly re-randomize the offset each repath so it doesn't look robotic/fixed
	SurroundOffset = SurroundOffset.RotateAngleAxis(FMath::RandRange(-15.0f, 15.0f), FVector::UpVector);

	const FVector TargetPoint = PlayerTank->GetActorLocation() + SurroundOffset;

	UNavigationPath* NavigationPath =
		UNavigationSystemV1::FindPathToLocationSynchronously(
			this,
			EnemyTank->GetActorLocation(),
			TargetPoint
		);

	if (NavigationPath && NavigationPath->IsValid() &&
		NavigationPath->PathPoints.Num() > 1)
	{
		EnemyTank->SetNavigationPath(NavigationPath->PathPoints);
	}
}

