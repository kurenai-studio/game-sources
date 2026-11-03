// Fill out your copyright notice in the Description page of Project Settings.


#include "ToonTanksPlayerController.h"

#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "Tank.h"

void AToonTanksPlayerController::OnPossess(APawn* aPawn)
{
	Super::OnPossess(aPawn);

	Tank = Cast<ATank>(aPawn);
	checkf(Tank, TEXT("The Pawn need to be a ATANK derivated class."));
	//Update to EnhancedInputComponent
	EnhancedInputComponent = Cast<UEnhancedInputComponent>(InputComponent);
	checkf(EnhancedInputComponent, TEXT("EnhancedInputComponent not found"));

	if (ActionFire)
	{
		EnhancedInputComponent->BindAction(ActionFire, ETriggerEvent::Started, this, &AToonTanksPlayerController::HandleFire);
		//GEngine->AddOnScreenDebugMessage(-1,15,FColor::Orange,TEXT("Fite enhancedInput"));
	}

	if (ActionMoveForward)
	{
		EnhancedInputComponent->BindAction(ActionMoveForward, ETriggerEvent::Triggered, this, &AToonTanksPlayerController::HandleMove);
	}
}

void AToonTanksPlayerController::OnUnPossess()
{
	Super::OnUnPossess();
}

void AToonTanksPlayerController::SetPlayerEnabledState(bool bPlayerEnabled)
{
	// Get the Local player subsystem.
	UEnhancedInputLocalPlayerSubsystem* InputSubsystem = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(GetLocalPlayer());
	checkf(InputSubsystem, TEXT("Unable to get reference to the EnhancedInputLocalPlayerSubsystem. "));
	InputSubsystem->ClearAllMappings();

	if (bPlayerEnabled)
	{
		GetPawn()->EnableInput(this);
		InputSubsystem->AddMappingContext(InputMappingContext, 0);
		bShowMouseCursor = bPlayerEnabled;
		DefaultMouseCursor = EMouseCursor::Crosshairs;
	}
	else
	{
		GetPawn()->DisableInput(this);
		DefaultMouseCursor = EMouseCursor::Default;
	}
}

void AToonTanksPlayerController::HandleFire()
{
	if (Tank)
	{
		Tank->Fire();
	}
}

void AToonTanksPlayerController::HandleMove(const FInputActionValue& InputAction)
{
	if (Tank)
	{
		Tank->Move(InputAction.Get<FVector2D>());
	}
}

