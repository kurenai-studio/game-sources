#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "UnrealEngineLearning/Interfaces/Damageable.h"
#include "PlayerCharater.generated.h"

UCLASS()
class UNREALENGINELEARNING_API APlayerCharater : public ACharacter, public IDamageable
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	APlayerCharater();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	void ScrollWeapon(float Input);
	void EquipWeapon(int32 Index);

	void MoveForward(float Input);
	void MoveRight(float Input);

	void LookUp(float Input);
	void LookRight(float Input);

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	void BeginFiring();
	void EndFiring();

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	// IDamageable interface implementation
	virtual void ApplyDamage(float DamageAmount) override;
	virtual float GetHealth() const override;
	virtual void SetHealth(float NewHealth) override;

	bool IsMoving = false;
	FVector2D InputVector;

protected:
	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<class AGun>> WeaponClasses;


	UPROPERTY(EditAnywhere)
	class UCameraComponent* Camera;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = CameraTilt)
	float CameraTiltAmount = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = CameraTilt)
	float CameraTiltSmoothTiming = 5.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
	USceneComponent* WeaponSocket;

private:
	UPROPERTY(EditAnywhere)
	float Health = 100.0f;

	AGun* CurrentWeapon = nullptr;
	int32 CurrentWeaponIndex = 0;
	float CurrentRoll = 0;
};
