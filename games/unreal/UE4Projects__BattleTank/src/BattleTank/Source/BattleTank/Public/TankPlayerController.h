// Copyright OurReality LLC

#pragma once

#include "GameFramework/PlayerController.h"
#include "TankPlayerController.generated.h" // Must be the last include

/**
 * 
 */
class ATank;

UCLASS()
class BATTLETANK_API ATankPlayerController : public APlayerController
{
	GENERATED_BODY()
	
	
public:

	virtual void BeginPlay() override;

	virtual void Tick(float DeltaTime) override;


private:

	ATank* GetControlledTank() const;
	// Start the tank moving the barrel so that a shot 
	// would hit where the crosshair intersects the world (convert 2d to 3d)
	void AimTowardsCrosshair();

	bool GetSightRayHitLocation(FVector& HitLocation) const;

	bool GetLookDirection(FVector2D ScreenLocation, FVector & LookDirection) const;

	UPROPERTY( EditAnywhere )
	float CrossHairXLocation = 0.5f;

	UPROPERTY(EditAnywhere)
	float CrossHairYLocation = 0.3333f;

	bool GetLookVectorHitLocation(FVector LookDirection, FVector& HitLocation) const;

	UPROPERTY(EditAnywhere)
	float LineTraceRange = 1000000;


};
