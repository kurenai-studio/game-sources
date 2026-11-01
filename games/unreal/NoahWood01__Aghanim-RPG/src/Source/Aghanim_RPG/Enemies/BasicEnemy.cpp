// Copyright (c) 2022 Noah Wood


#include "BasicEnemy.h"

// Sets default values
ABasicEnemy::ABasicEnemy()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	maxHealth = 100.0f;
	health = maxHealth;
	dead = false;
	takenDamage = false;
}

// Called when the game starts or when spawned
void ABasicEnemy::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void ABasicEnemy::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void ABasicEnemy::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

}

void ABasicEnemy::takeDamage(float damageAmount)
{
	if (!takenDamage)
	{
		health -= damageAmount;

		if (health <= 0.0f)
		{
			dead = true;
		}	
		else
		{
			takenDamage = true;
		}		
	}
}

void ABasicEnemy::die()
{
	dead = true;
	//notifyDeath();
}


