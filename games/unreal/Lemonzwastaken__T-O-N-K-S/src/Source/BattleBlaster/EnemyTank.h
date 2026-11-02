#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "Tank.h"
#include "EnemyTank.generated.h"

UCLASS()
class BATTLEBLASTER_API AEnemyTank : public ABasePawn
{
	GENERATED_BODY()

protected:
	virtual void BeginPlay() override;

public:
	AEnemyTank();

	virtual void Tick(float DeltaTime) override;

	virtual UPawnMovementComponent* GetMovementComponent() const override;

	UPROPERTY(VisibleAnywhere)
	UFloatingPawnMovement* MovementComp;

	UPROPERTY(EditAnywhere)
	float FireRange = 1000.0f;

	UPROPERTY(EditAnywhere)
	float FireRate = 2.0f;

	UPROPERTY(EditAnywhere)
	float HullTurnSpeed = 5.0f;

	UPROPERTY(EditAnywhere)
	float ChaseStopDistance = 900.0f;

	UPROPERTY(EditAnywhere)
	float ChaseSpeed = 1.0f;

	UPROPERTY()
	ATank* Tank;

	void SetNavigationPath(const TArray<FVector>& NewPathPoints);
	void CheckFireCondition();
	bool IsInFireRange();
	void HandleDestruction();




private:
	bool FollowNavigationPath();

	TArray<FVector> NavigationPathPoints;
	int32 CurrentPathPointIndex = 0;

	UPROPERTY(EditAnywhere, Category = "Navigation")
	float PathPointAcceptanceRadius = 75.0f;

	UPROPERTY(EditAnywhere, Category = "Randomization")
	float SpeedVariance = 0.25f; // +/-25%

	UPROPERTY(EditAnywhere, Category = "Randomization")
	float FireRateVariance = 0.3f; // +/-30%

};
