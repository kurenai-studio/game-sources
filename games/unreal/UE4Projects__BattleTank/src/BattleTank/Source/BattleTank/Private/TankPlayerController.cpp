// Copyright OurReality LLC

#include "BattleTank.h"
#include "Tank.h"
#include "TankPlayerController.h"


void ATankPlayerController::BeginPlay()
{
	Super::BeginPlay();

	//UE_LOG(LogTemp, Warning, TEXT("PlayerController Begin Play"));


	auto ControlledTank = GetControlledTank();


	if (ControlledTank)
	{ 
		UE_LOG(LogTemp, Warning, TEXT("Player Controller possesing: %s"), *(ControlledTank->GetName()) );
	}
	else {
		UE_LOG(LogTemp, Error, TEXT("ControlledTank not found!"));
	}


}

void ATankPlayerController::Tick(float DeltaTime) 
{
	Super::Tick(DeltaTime);
	//UE_LOG(LogTemp, Warning, TEXT("TankPlayerController Ticking"));

	AimTowardsCrosshair();

}



ATank* ATankPlayerController::GetControlledTank() const
{
	return Cast<ATank>(GetPawn());
}

void ATankPlayerController::AimTowardsCrosshair()
{

	if (!GetControlledTank()) { return; }

	FVector HitLocation; // Out parameter
	if (GetSightRayHitLocation(HitLocation))
	{
		//UE_LOG(LogTemp, Warning, TEXT("HitLocation: %s"), *HitLocation.ToString());
		GetControlledTank()->AimAt(HitLocation);
	}


}


// Get world location of linetrace through crosshair, true if hits landscape
bool ATankPlayerController::GetSightRayHitLocation(FVector& HitLocation) const
{
	//Find the crosshair position in pixel coordinates
	int32 ViewportSizeX, ViewportSizeY;
	GetViewportSize(ViewportSizeX, ViewportSizeY);

	auto ScreenLocation = FVector2D(ViewportSizeX * CrossHairXLocation,
		ViewportSizeY * CrossHairYLocation);
	//UE_LOG(LogTemp, Warning, TEXT("screenlocation: %s"), *(ScreenLocation.ToString()));

	FVector LookDirection;
	if (GetLookDirection(ScreenLocation, LookDirection))
	{
		// Line-trace along that LookDirection, and see whate we hit (up to max range)
		GetLookVectorHitLocation(LookDirection, HitLocation);

	}

	return true;
}

bool ATankPlayerController::GetLookDirection(FVector2D ScreenLocation, FVector& LookDirection) const
{
	FVector CameraWorldLocation; // To be discarded....

	return DeprojectScreenPositionToWorld(
		ScreenLocation.X,
		ScreenLocation.Y,
		CameraWorldLocation,
		LookDirection);

}

bool ATankPlayerController::GetLookVectorHitLocation(FVector LookDirection, FVector& HitLocation) const
{
	FHitResult HitResult;
	FVector StartLocation = PlayerCameraManager->GetCameraLocation();
	FVector EndLocation = StartLocation + (LookDirection * LineTraceRange);

	if (GetWorld()->LineTraceSingleByChannel(
			HitResult,
			StartLocation,
			EndLocation,
			ECollisionChannel::ECC_Visibility)
		)
	{
		HitLocation = HitResult.Location;
		return true;
	}
	HitLocation = FVector(0);
	return false;
}
