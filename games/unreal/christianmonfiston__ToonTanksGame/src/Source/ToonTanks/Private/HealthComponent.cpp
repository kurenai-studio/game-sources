// Fill out your copyright notice in the Description page of Project Settings.


#include "DrawDebugHelpers.h "

#include "DrawDebugHelpers.h "

#include "HealthComponent.h"

// Sets default values for this component's properties
UHealthComponent::UHealthComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;


	Health = 0.f; 

	MaxHealth = Health; 
	
}


// Called when the game starts
void UHealthComponent::BeginPlay()
{
	Super::BeginPlay();

	if (GEngine) {

		GEngine->AddOnScreenDebugMessage(-1, 15.f, FColor::Cyan, TEXT("HEALTH COMPONENT IS WORKING")); 
	}
	
}


// Called every frame
void UHealthComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	Health++; 

	
	if (Health == 100.f) {

		MaxHealth = 100.f;
	}
}

