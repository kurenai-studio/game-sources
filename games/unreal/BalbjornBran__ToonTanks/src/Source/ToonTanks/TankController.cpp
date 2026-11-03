// Created by Balbjorn Bran.


#include "TankController.h"
#include "Tank.h"
#include "EnhancedInputSubsystems.h"


void ATankController::BeginPlay()
{
	Super::BeginPlay();
	
}

void ATankController::SetupInputComponent()
{
	Super::SetupInputComponent();

	if (UEnhancedInputLocalPlayerSubsystem* Subsystem = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(GetLocalPlayer()))
	{
		// add the mapping context so we get controls
		Subsystem->AddMappingContext(InputMappingContext, 0);		
	}
}

void ATankController::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);

	// get a pointer to the controlled pawn
	VehiclePawn = CastChecked<ATank>(InPawn);
}

void ATankController::Tick(float Delta)
{
	Super::Tick(Delta);
}

void ATankController::SetPlayerEnabledState(bool bEnabled)
{
	if (bEnabled)
	{
		VehiclePawn->EnableInput(this);
	}
	else
	{
		VehiclePawn->DisableInput(this);
	}
	bShowMouseCursor = bEnabled;
}

