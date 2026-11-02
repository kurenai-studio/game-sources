// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaPlayerController.h"

#include "ArenaCharacter.h"
#include "ArenaHUD.h"

#include "GameFramework/Pawn.h"
#include "Kismet/GameplayStatics.h"

// ---------------------------------------------------------------------------
// Shared layout
// ---------------------------------------------------------------------------

namespace ArenaTouch
{
	float GetUIScale(const FVector2D& ViewportSize)
	{
		const float Scale = ViewportSize.Y / DesignHeight;
		return FMath::Clamp(Scale, 0.65f, 1.9f);
	}

	float GetJoystickRadius(const FVector2D& ViewportSize)
	{
		return 112.f * GetUIScale(ViewportSize);
	}

	float GetJoystickKnobRadius(const FVector2D& ViewportSize)
	{
		return 46.f * GetUIScale(ViewportSize);
	}

	float GetButtonRadius(const FVector2D& ViewportSize)
	{
		return 62.f * GetUIScale(ViewportSize);
	}

	FVector2D GetJoystickRestCenter(const FVector2D& ViewportSize)
	{
		const float Scale = GetUIScale(ViewportSize);
		return FVector2D(150.f * Scale, ViewportSize.Y - 150.f * Scale);
	}

	FVector2D GetJumpButtonCenter(const FVector2D& ViewportSize)
	{
		const float Scale = GetUIScale(ViewportSize);
		return FVector2D(ViewportSize.X - 120.f * Scale, ViewportSize.Y - 130.f * Scale);
	}

	FVector2D GetSprintButtonCenter(const FVector2D& ViewportSize)
	{
		const float Scale = GetUIScale(ViewportSize);
		return FVector2D(ViewportSize.X - 268.f * Scale, ViewportSize.Y - 96.f * Scale);
	}
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

AArenaPlayerController::AArenaPlayerController()
{
	bShowMouseCursor = false;
	bEnableClickEvents = false;
	bEnableMouseOverEvents = false;
	bEnableTouchEvents = true;
}

void AArenaPlayerController::BeginPlay()
{
	Super::BeginPlay();

	FInputModeGameOnly InputMode;
	SetInputMode(InputMode);
	bShowMouseCursor = false;
}

void AArenaPlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();

	if (!InputComponent)
	{
		return;
	}

	InputComponent->BindAction(TEXT("Pause"), IE_Pressed, this, &AArenaPlayerController::TogglePause);

	InputComponent->BindTouch(IE_Pressed, this, &AArenaPlayerController::OnTouchPressed);
	InputComponent->BindTouch(IE_Repeat, this, &AArenaPlayerController::OnTouchMoved);
	InputComponent->BindTouch(IE_Released, this, &AArenaPlayerController::OnTouchReleased);
}

void AArenaPlayerController::PlayerTick(float DeltaTime)
{
	Super::PlayerTick(DeltaTime);

	if (!bMoveFingerActive)
	{
		return;
	}

	if (AArenaCharacter* Character = Cast<AArenaCharacter>(GetPawn()))
	{
		Character->AddTouchMoveInput(MoveInput.Y, MoveInput.X);
	}
}

// ---------------------------------------------------------------------------
// Touch input
// ---------------------------------------------------------------------------

void AArenaPlayerController::OnTouchPressed(ETouchIndex::Type FingerIndex, FVector Location)
{
	int32 SizeX = 0;
	int32 SizeY = 0;
	GetViewportSize(SizeX, SizeY);
	const FVector2D Viewport(static_cast<float>(SizeX), static_cast<float>(SizeY));
	const FVector2D Position(Location.X, Location.Y);

	// Buttons win over the movement / look zones.
	if (TryPressTouchButton(Position, Viewport))
	{
		return;
	}

	// Left half: floating virtual stick. Right half: camera look.
	if (Position.X < Viewport.X * 0.5f)
	{
		if (bMoveFingerActive)
		{
			return;
		}

		bMoveFingerActive = true;
		MoveFinger = FingerIndex;
		MoveOrigin = Position;
		MoveCurrent = Position;
		MoveInput = FVector2D::ZeroVector;
	}
	else if (!bLookFingerActive)
	{
		bLookFingerActive = true;
		LookFinger = FingerIndex;
		LookLast = Position;
	}
}

void AArenaPlayerController::OnTouchMoved(ETouchIndex::Type FingerIndex, FVector Location)
{
	const FVector2D Position(Location.X, Location.Y);

	if (bMoveFingerActive && FingerIndex == MoveFinger)
	{
		UpdateTouchMove(Position.X, Position.Y);
	}
	else if (bLookFingerActive && FingerIndex == LookFinger)
	{
		const FVector2D Delta = Position - LookLast;
		LookLast = Position;
		ApplyTouchLook(Delta.X, Delta.Y);
	}
}

void AArenaPlayerController::OnTouchReleased(ETouchIndex::Type FingerIndex, FVector Location)
{
	if (bMoveFingerActive && FingerIndex == MoveFinger)
	{
		bMoveFingerActive = false;
		MoveInput = FVector2D::ZeroVector;
	}

	if (bLookFingerActive && FingerIndex == LookFinger)
	{
		bLookFingerActive = false;
	}
}

void AArenaPlayerController::UpdateTouchMove(float LocationX, float LocationY)
{
	int32 SizeX = 0;
	int32 SizeY = 0;
	GetViewportSize(SizeX, SizeY);
	const FVector2D Viewport(static_cast<float>(SizeX), static_cast<float>(SizeY));

	MoveCurrent = FVector2D(LocationX, LocationY);

	const float Radius = FMath::Max(1.f, ArenaTouch::GetJoystickRadius(Viewport));
	FVector2D Offset = MoveCurrent - MoveOrigin;

	// Clamp the knob to the outer ring so the visuals stay readable.
	if (Offset.SizeSquared() > Radius * Radius)
	{
		Offset = Offset.GetSafeNormal() * Radius;
		MoveCurrent = MoveOrigin + Offset;
	}

	MoveInput = Offset / Radius;
}

void AArenaPlayerController::ApplyTouchLook(float DeltaX, float DeltaY)
{
	FRotator Rotation = GetControlRotation();
	Rotation.Yaw += DeltaX * TouchLookSensitivity;
	Rotation.Pitch = FMath::Clamp(Rotation.Pitch - DeltaY * TouchLookSensitivity, -75.f, 75.f);
	SetControlRotation(Rotation);
}

bool AArenaPlayerController::TryPressTouchButton(const FVector2D& TouchPosition, const FVector2D& ViewportSize)
{
	const float Radius = ArenaTouch::GetButtonRadius(ViewportSize);
	const float RadiusSq = Radius * Radius;

	if (FVector2D::DistSquared(TouchPosition, ArenaTouch::GetJumpButtonCenter(ViewportSize)) <= RadiusSq)
	{
		if (AArenaCharacter* Character = Cast<AArenaCharacter>(GetPawn()))
		{
			Character->TouchJump();
		}
		return true;
	}

	if (FVector2D::DistSquared(TouchPosition, ArenaTouch::GetSprintButtonCenter(ViewportSize)) <= RadiusSq)
	{
		bTouchSprint = !bTouchSprint;
		if (AArenaCharacter* Character = Cast<AArenaCharacter>(GetPawn()))
		{
			Character->SetSprinting(bTouchSprint);
		}
		return true;
	}

	return false;
}

// ---------------------------------------------------------------------------
// Pause
// ---------------------------------------------------------------------------

void AArenaPlayerController::TogglePause()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	const bool bIsPaused = UGameplayStatics::IsGamePaused(this);
	UGameplayStatics::SetGamePaused(this, !bIsPaused);

	if (AArenaHUD* HUD = Cast<AArenaHUD>(GetHUD()))
	{
		if (!bIsPaused)
		{
			HUD->ShowMessage(TEXT("PAUSED"), FLinearColor(0.8f, 0.9f, 1.f), 4.f);
		}
	}
}
