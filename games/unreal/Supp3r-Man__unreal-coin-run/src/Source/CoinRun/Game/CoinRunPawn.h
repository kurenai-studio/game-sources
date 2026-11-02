#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "CoinRunPawn.generated.h"

class UCameraComponent;
class UMaterialInstanceDynamic;
class UMaterialInterface;
class USceneComponent;
class USpringArmComponent;
class UStaticMeshComponent;

/**
 * The player's body and a fixed top-down camera. It does no gameplay of its own: the director reads the
 * keyboard, runs the rules and moves this pawn. Keeping the pawn passive means all game logic is in one place.
 */
UCLASS()
class COINRUN_API ACoinRunPawn : public APawn
{
	GENERATED_BODY()

public:
	ACoinRunPawn();

	virtual void BeginPlay() override;

	/** Used for the blink while invulnerable. */
	void SetBodyVisible(bool bVisible);

private:
	UPROPERTY(VisibleAnywhere)
	TObjectPtr<USceneComponent> Root;

	UPROPERTY(VisibleAnywhere)
	TObjectPtr<UStaticMeshComponent> Body;

	UPROPERTY(VisibleAnywhere)
	TObjectPtr<USpringArmComponent> Arm;

	UPROPERTY(VisibleAnywhere)
	TObjectPtr<UCameraComponent> Camera;

	UPROPERTY()
	TObjectPtr<UMaterialInterface> BaseMaterial;

	UPROPERTY()
	TObjectPtr<UMaterialInstanceDynamic> BodyMaterial;
};
