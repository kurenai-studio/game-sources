#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "SeagullPlayerPawn.generated.h"

class UPaperFlipbook;
class UPaperFlipbookComponent;
class UFloatingPawnMovement;
class USphereComponent;
class UCameraComponent;
class USpringArmComponent;
class USeagullHealthComponent;
class USeagullXPComponent;
class USeagullWeaponManager;
class USeagullCutoutRigComponent;

UCLASS()
class ASeagullPlayerPawn : public APawn
{
	GENERATED_BODY()

public:
	ASeagullPlayerPawn();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	UPROPERTY(VisibleAnywhere)
	USphereComponent* CollisionComponent;

	UPROPERTY(VisibleAnywhere)
	UPaperFlipbookComponent* SpriteComponent;

	UPROPERTY(VisibleAnywhere)
	USeagullCutoutRigComponent* CutoutRig;

	UPROPERTY(VisibleAnywhere)
	UFloatingPawnMovement* MovementComponent;

	UPROPERTY(VisibleAnywhere)
	USpringArmComponent* SpringArm;

	UPROPERTY(VisibleAnywhere)
	UCameraComponent* Camera;

	UPROPERTY(VisibleAnywhere)
	USeagullHealthComponent* HealthComponent;

	UPROPERTY(VisibleAnywhere)
	USeagullXPComponent* XPComponent;

	UPROPERTY(VisibleAnywhere)
	USeagullWeaponManager* WeaponManager;

	// Flipbooks loaded from canonical /Game/Flipbooks paths (null until the
	// Paper2D assets are created in the editor, see EDITOR_SETUP.md)
	UPROPERTY()
	UPaperFlipbook* IdleFlipbook = nullptr;

	UPROPERTY()
	UPaperFlipbook* WalkFlipbook = nullptr;

	UPROPERTY()
	UPaperFlipbook* HurtFlipbook = nullptr;

	UPROPERTY()
	UPaperFlipbook* DeathFlipbook = nullptr;

	float BaseSpeed = 200.f;
	FVector2D LastMoveDirection = FVector2D(1.f, 0.f);

	void ApplyUpgrades();
	void PlayAttackPose();

	UFUNCTION()
	void OnDeath();

	UFUNCTION()
	void OnHealthChangedHandler(int32 Current, int32 Max);

private:
	void UpdateFlipbookState(float DeltaTime);

	float HurtFlashTimer = 0.f;
	int32 LastKnownHP = 0;
};
