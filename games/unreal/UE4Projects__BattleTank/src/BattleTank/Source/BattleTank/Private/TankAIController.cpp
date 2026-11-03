// Copyright OurReality LLC

#include "BattleTank.h"
#include "Tank.h"
#include "TankAIController.h"



void ATankAIController::BeginPlay()
{

	Super::BeginPlay();


	auto PlayerTank = GetPlayerTank();

	if (!PlayerTank)
	{
		UE_LOG(LogTemp, Warning, TEXT("AIController can't find player tank"));
	}
	else {
		UE_LOG(LogTemp, Warning, TEXT("AIController found player tank: %s"), *(PlayerTank->GetName()));
	}




}

void ATankAIController::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);


	if (!GetPlayerTank()) { return; }
	{
		FVector PlayerTankLocation = GetPlayerTank()->GetActorLocation();

		GetAIControlledTank()->AimAt(PlayerTankLocation); // section 4 lec: 126 His is named GetContolledTank now?
	
	}



}

ATank* ATankAIController::GetAIControlledTank() const
{

	return Cast<ATank>(GetPawn());
}

ATank* ATankAIController::GetPlayerTank() const
{

	auto PlayerPawn = GetWorld()->GetFirstPlayerController()->GetPawn();

	if (!PlayerPawn) { return nullptr; }

	return Cast<ATank>(PlayerPawn);
}
