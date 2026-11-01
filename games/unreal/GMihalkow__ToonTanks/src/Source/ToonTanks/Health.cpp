// Fill out your copyright notice in the Description page of Project Settings.


#include "Health.h"

// Sets default values for this component's properties
UHealth::UHealth()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UHealth::BeginPlay()
{
	Super::BeginPlay();

	this->_currentHealth = this->_maxHealth;
	this->GetOwner()->OnTakeAnyDamage.AddDynamic(this, &UHealth::DamageTaken);
}


// Called every frame
void UHealth::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

bool UHealth::IsDead() const
{
	return this->_currentHealth <= 0;
}

void UHealth::DamageTaken(AActor* damagedActor, float damage, const UDamageType* type, AController* instigator, AActor* causer)
{
	if (this->_currentHealth <= 0)
	{
		return;
	}

	this->_currentHealth -= damage;

	UE_LOG(LogTemp, Log, TEXT("HEALTH REMAINING -> %f"), this->_currentHealth);

	if (this->_currentHealth <= 0)
	{
		this->_currentHealth = 0;
		this->onDeathEvent.Broadcast();
	}
}