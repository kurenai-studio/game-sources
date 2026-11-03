#include "PingPongPlayerController.h"

APingPongPlayerController::APingPongPlayerController()
{
	MoveAxis = 0.f;
}

void APingPongPlayerController::BeginPlay()
{
	Super::BeginPlay();

	FInputModeGameOnly InputMode;
	SetInputMode(InputMode);
	bShowMouseCursor = false;
}

void APingPongPlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();

	InputComponent->BindAxis("MovePlayer", this, &APingPongPlayerController::OnMoveAxis);
	InputComponent->BindAction("Quit", IE_Pressed, this, &APingPongPlayerController::OnQuit);
}

void APingPongPlayerController::OnMoveAxis(float Value)
{
	MoveAxis = Value;
}

void APingPongPlayerController::OnQuit()
{
	ConsoleCommand(TEXT("quit"));
}
