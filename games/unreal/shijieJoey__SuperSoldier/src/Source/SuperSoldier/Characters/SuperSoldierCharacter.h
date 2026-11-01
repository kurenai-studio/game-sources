// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "SuperSoldierCharacter.generated.h"

UCLASS()
class SUPERSOLDIER_API ASuperSoldierCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	ASuperSoldierCharacter();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	void Shoot();

	virtual float TakeDamage(float DamageAmount, struct FDamageEvent const & DamageEvent, class AController* EventInstigator, AActor* DamageCauser) override;

	UFUNCTION(BlueprintPure)
	bool IsDead() const;

	UFUNCTION(BlueprintPure)
	float GetHealthPercent() const;

	UFUNCTION(BlueprintPure)
	float GetArmorPercent() const;

	UFUNCTION(BlueprintPure)
	float GetArmor() const;

private:

	void InitializeComponents();
	void InitializeGuns();
	void InitializeCharacterStats();
	void MoveForward(float AxisValue);
	void MoveRight(float AxisValue);
	void SwitchWeapon1();
	void SwitchWeapon2();
	void SwitchWeapon3();
	void AttachGunToPlayer(class AGunBase* Gun);
	void HideOriginGunMesh();
	void ShowOriginGunMesh();
	void HideOrShowGun(int32 IndexOfGun, bool ToHide);


	// Components
	UPROPERTY(VisibleAnywhere)
	class USpringArmComponent* SpringArm;
	UPROPERTY(VisibleAnywhere)
	class UCameraComponent* Camera;
	// Weapons
	UPROPERTY(EditAnywhere)
	TArray<TSubclassOf<class AGunBase>> GunClasses;
	UPROPERTY()
	TArray<class AGunBase*> Guns; 
	int32 IndexOfCurrentGun;
	UPROPERTY(EditAnywhere)
	FString GunAttachedBoneName = "weapon_r";

	// PlayerStats
	UPROPERTY(EditAnywhere)
	float MaxHealth = 1000.f;
	UPROPERTY(VisibleAnywhere)
	float Health;
	UPROPERTY(EditAnywhere)
	float MaxArmor = 50.f;
	UPROPERTY(VisibleAnywhere)
	float Armor;
	UPROPERTY(EditAnywhere)
	int32 DefaultGunIndex = 0;
};
