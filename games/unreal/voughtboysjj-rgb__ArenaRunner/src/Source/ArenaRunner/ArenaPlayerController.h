// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "InputCoreTypes.h"
#include "ArenaPlayerController.generated.h"

/**
 * Shared on-screen control layout. Both the controller (hit testing) and the HUD
 * (drawing) use these helpers so the visuals and the touch zones can never drift apart.
 * All values are expressed in pixels at a 1080p reference height and scaled at runtime.
 */
namespace ArenaTouch
{
	constexpr float DesignHeight = 1080.f;

	ARENARUNNER_API float GetUIScale(const FVector2D& ViewportSize);
	ARENARUNNER_API float GetJoystickRadius(const FVector2D& ViewportSize);
	ARENARUNNER_API float GetJoystickKnobRadius(const FVector2D& ViewportSize);
	ARENARUNNER_API float GetButtonRadius(const FVector2D& ViewportSize);
	ARENARUNNER_API FVector2D GetJoystickRestCenter(const FVector2D& ViewportSize);
	ARENARUNNER_API FVector2D GetJumpButtonCenter(const FVector2D& ViewportSize);
	ARENARUNNER_API FVector2D GetSprintButtonCenter(const FVector2D& ViewportSize);
}

/**
 * Player controller for both desktop and mobile:
 *  - desktop: classic input mappings from Config/DefaultInput.ini
 *  - mobile:  a floating virtual stick (left half of the screen), a look area
 *             (right half), plus jump and sprint buttons drawn by the HUD
 */
UCLASS()
class ARENARUNNER_API AArenaPlayerController : public APlayerController
{
	GENERATED_BODY()

public:
	AArenaPlayerController();

	virtual void BeginPlay() override;
	virtual void SetupInputComponent() override;
	virtual void PlayerTick(float DeltaTime) override;

	// ---- Touch state queried by the HUD ----
	bool IsTouchMoveActive() const { return bMoveFingerActive; }
	FVector2D GetTouchMoveOrigin() const { return MoveOrigin; }
	FVector2D GetTouchMoveCurrent() const { return MoveCurrent; }
	bool IsTouchSprintOn() const { return bTouchSprint; }

	/** Degrees of rotation per screen pixel for the touch look area. */
	UPROPERTY(EditDefaultsOnly, Category = "Touch")
	float TouchLookSensitivity = 0.14f;

private:
	void TogglePause();

	// Touch handlers (signature required by UInputComponent::BindTouch).
	void OnTouchPressed(ETouchIndex::Type FingerIndex, FVector Location);
	void OnTouchMoved(ETouchIndex::Type FingerIndex, FVector Location);
	void OnTouchReleased(ETouchIndex::Type FingerIndex, FVector Location);

	void UpdateTouchMove(float LocationX, float LocationY);
	void ApplyTouchLook(float DeltaX, float DeltaY);
	bool TryPressTouchButton(const FVector2D& TouchPosition, const FVector2D& ViewportSize);

	// Virtual stick
	bool bMoveFingerActive = false;
	ETouchIndex::Type MoveFinger = ETouchIndex::Touch1;
	FVector2D MoveOrigin = FVector2D::ZeroVector;
	FVector2D MoveCurrent = FVector2D::ZeroVector;
	FVector2D MoveInput = FVector2D::ZeroVector;

	// Look finger
	bool bLookFingerActive = false;
	ETouchIndex::Type LookFinger = ETouchIndex::Touch1;
	FVector2D LookLast = FVector2D::ZeroVector;

	bool bTouchSprint = false;
};
