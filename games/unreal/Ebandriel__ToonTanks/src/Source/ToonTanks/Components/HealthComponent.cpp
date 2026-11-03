// Fill out your copyright notice in the Description page of Project Settings.


#include "HealthComponent.h"
#include "ToonTanks/GameModes/TankGameModeBase.h"
#include "Kismet/GameplayStatics.h"

// Sets default values
UHealthComponent::UHealthComponent()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryComponentTick.bCanEverTick = false;

}

// Called when the game starts or when spawned
void UHealthComponent::BeginPlay()
{
	Super::BeginPlay();

	Health = DefaultHealth;
	GameModeRef = Cast<ATankGameModeBase>(UGameplayStatics::GetGameMode(GetWorld()));
	GetOwner()->OnTakeAnyDamage.AddDynamic(this, &UHealthComponent::TakeDamage);
	
}

void UHealthComponent::TakeDamage(AActor* DamagedActor, float Dammage, const UDamageType* DamageType, AController* InstigatedBy, AActor* DamageCauser)
{
	if (Dammage == 0 || Health <= 0)
	{
		return;
	}
	Health = FMath::Clamp(Health - Dammage, 0.0f, DefaultHealth);
	if (Health <= 0)
	{
		if (GameModeRef)
		{
			GameModeRef->ActorDied(GetOwner());
		}
		else
		{
			UE_LOG(LogTemp, Warning, TEXT("HEalth Component has no reference to the game mode"));
		}
	}
}


