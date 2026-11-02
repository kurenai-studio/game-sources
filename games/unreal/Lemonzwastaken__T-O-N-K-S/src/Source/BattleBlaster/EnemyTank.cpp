#include "EnemyTank.h"
#include "EnemyAIController.h"
#include "Kismet/GameplayStatics.h"

AEnemyTank::AEnemyTank()
{
	MovementComp = CreateDefaultSubobject<UFloatingPawnMovement>(
		TEXT("MovementComp")
	);

	MovementComp->SetUpdatedComponent(CapsuleComp);
	MovementComp->MaxSpeed = 300.0f;
	MovementComp->Acceleration = 800.0f;
	MovementComp->Deceleration = 1200.0f;

	AIControllerClass = AEnemyAIController::StaticClass();
	AutoPossessAI = EAutoPossessAI::PlacedInWorldOrSpawned;
}

void AEnemyTank::BeginPlay()
{
	Super::BeginPlay();

	Tank = Cast<ATank>(
		UGameplayStatics::GetPlayerPawn(GetWorld(), 0)
	);

	const float SpeedMult = FMath::RandRange(1.0f - SpeedVariance, 1.0f + SpeedVariance);
	MovementComp->MaxSpeed *= SpeedMult;
	MovementComp->Acceleration *= SpeedMult;
	HullTurnSpeed *= FMath::RandRange(0.8f, 1.2f);


	const float RandomizedFireRate =
		FireRate * FMath::RandRange(1.0f - FireRateVariance, 1.0f + FireRateVariance);
	const float InitialFireDelay = FMath::RandRange(0.0f, RandomizedFireRate);

	FTimerHandle FireTimerHandle;
	GetWorldTimerManager().SetTimer(
		FireTimerHandle,
		this,
		&AEnemyTank::CheckFireCondition,
		RandomizedFireRate,
		true,
		InitialFireDelay
	);
}

void AEnemyTank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (!Tank)
	{
		Tank = Cast<ATank>(
			UGameplayStatics::GetPlayerPawn(GetWorld(), 0)
		);
	}

	if (!Tank || !Tank->IsAlive || !MovementComp)
	{
		return;
	}

	FVector DirectionToTank =
		Tank->GetActorLocation() - GetActorLocation();

	DirectionToTank.Z = 0.0f;

	const float DistanceToTank = DirectionToTank.Size();
	
	if (DistanceToTank > ChaseStopDistance)
	{
		FollowNavigationPath();
	}
	else
	{
		MovementComp->StopMovementImmediately();
	}

	RotateTurret(Tank->GetActorLocation());

	const FVector Velocity = MovementComp->Velocity;

	if (!Velocity.IsNearlyZero())
	{
		const FRotator TargetRotation(
			0.0f,
			Velocity.Rotation().Yaw,
			0.0f
		);

		SetActorRotation(
			FMath::RInterpTo(
				GetActorRotation(),
				TargetRotation,
				DeltaTime,
				HullTurnSpeed
			)
		);
	}
}

UPawnMovementComponent* AEnemyTank::GetMovementComponent() const
{
	return MovementComp;
}

void AEnemyTank::CheckFireCondition()
{
	if (Tank && Tank->IsAlive && IsInFireRange())
	{
		Fire();
	}
}

bool AEnemyTank::IsInFireRange()
{
	if (!Tank)
	{
		return false;
	}

	return FVector::Dist(
		GetActorLocation(),
		Tank->GetActorLocation()
	) <= FireRange;
}

void AEnemyTank::HandleDestruction()
{
	Super::HandleDestruction();
	Destroy();
}

void AEnemyTank::SetNavigationPath(const TArray<FVector>& NewPathPoints)
{
	NavigationPathPoints = NewPathPoints;
	CurrentPathPointIndex = 0;
}

bool AEnemyTank::FollowNavigationPath()
{
	if (!MovementComp)
	{
		return false;
	}

	// No path yet, or path fully consumed — don't just sit idle
	if (NavigationPathPoints.IsEmpty() || CurrentPathPointIndex >= NavigationPathPoints.Num())
	{
		if (AEnemyAIController* AIController = Cast<AEnemyAIController>(GetController()))
		{
			AIController->RequestImmediateRepath();
		}
		if (Tank)
		{
			FVector DirectionToTank = Tank->GetActorLocation() - GetActorLocation();
			DirectionToTank.Z = 0.0f;

			if (DirectionToTank.SizeSquared() <= FMath::Square(PathPointAcceptanceRadius * 3.0f))
			{
				MovementComp->AddInputVector(DirectionToTank.GetSafeNormal(), true);
				return true;
			}
		}

		return false; // stay put and wait for the repath instead of cutting through walls/off-mesh
	}

	while (CurrentPathPointIndex < NavigationPathPoints.Num())
	{
		FVector DirectionToWaypoint =
			NavigationPathPoints[CurrentPathPointIndex] - GetActorLocation();
		DirectionToWaypoint.Z = 0.0f;

		if (DirectionToWaypoint.SizeSquared() <=
			FMath::Square(PathPointAcceptanceRadius))
		{
			++CurrentPathPointIndex;
			continue;
		}

		MovementComp->AddInputVector(DirectionToWaypoint.GetSafeNormal(), true);
		return true;
	}

	return false;
}
