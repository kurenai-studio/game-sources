// Copyright (c) 2022 Noah Wood

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "BasicEnemy.generated.h"

UCLASS()
class AGHANIM_RPG_API ABasicEnemy : public ACharacter
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	ABasicEnemy();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	// basic stats for enemy
	UFUNCTION(BlueprintCallable)
		void takeDamage(float damageAmount);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Enemy)
		float health;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Enemy)
		float maxHealth;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Enemy)
		bool takenDamage;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Enemy)
		bool dead;

	UFUNCTION(BlueprintCallable)
		void die();

	UFUNCTION(BlueprintImplementableEvent)
		void notifyDeath();

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

};
