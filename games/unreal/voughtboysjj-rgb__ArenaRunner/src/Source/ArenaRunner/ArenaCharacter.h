// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DamageEvents.h"
#include "GameFramework/Character.h"
#include "ArenaCharacter.generated.h"

class UCameraComponent;
class UMaterialInstanceDynamic;
class USpringArmComponent;
class UStaticMeshComponent;

/**
 * Third-person player character.
 *
 * The visual representation is built from engine primitives (cylinder body + sphere head)
 * so the project runs without any imported content. Swap BodyMesh/HeadMesh for a real
 * SkeletalMesh later if you want a proper character.
 */
UCLASS()
class ARENARUNNER_API AArenaCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	AArenaCharacter();

	virtual void Tick(float DeltaSeconds) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
	virtual float TakeDamage(float DamageAmount, const FDamageEvent& DamageEvent, AController* EventInstigator, AActor* DamageCauser) override;

	/** Teleports the character to the spawn point and restores health / movement. */
	void ResetForRun(const FVector& Location, const FRotator& Rotation);

	// ---- Touch / UI driven input (used by the on-screen mobile controls) ----

	void AddTouchMoveInput(float ForwardAmount, float RightAmount);
	void SetSprinting(bool bEnabled);
	void TouchJump();

	float GetHealth() const { return Health; }
	float GetMaxHealth() const { return MaxHealth; }
	float GetHealthPercent() const { return MaxHealth > 0.f ? FMath::Clamp(Health / MaxHealth, 0.f, 1.f) : 0.f; }
	bool IsSprinting() const { return bSprinting; }
	bool IsDead() const { return bDead; }

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Camera")
	TObjectPtr<USpringArmComponent> CameraBoom;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Camera")
	TObjectPtr<UCameraComponent> FollowCamera;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Visuals")
	TObjectPtr<UStaticMeshComponent> BodyMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Visuals")
	TObjectPtr<UStaticMeshComponent> HeadMesh;

	// ---- Tunables (edit in the editor or in ArenaCharacter.cpp) ----------------

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float MaxHealth = 100.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float WalkSpeed = 430.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float SprintSpeed = 780.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float HealthRegenPerSecond = 7.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float HealthRegenDelay = 3.f;

	/** Invulnerability window after being hit, in seconds. */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float DamageCooldown = 0.7f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Stats")
	float KnockBackStrength = 420.f;

private:
	void MoveForward(float Value);
	void MoveRight(float Value);
	void Turn(float Value);
	void LookUp(float Value);
	void BeginSprint();
	void EndSprint();
	void DoJump();
	void StopJump();

	UPROPERTY(Transient)
	TObjectPtr<UMaterialInstanceDynamic> BodyMaterial;

	float Health = 100.f;
	float LastDamageTime = -1000.f;
	bool bSprinting = false;
	bool bDead = false;
};
