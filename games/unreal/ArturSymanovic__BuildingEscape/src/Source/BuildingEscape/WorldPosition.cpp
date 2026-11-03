// Fill out your copyright notice in the Description page of Project Settings.


#include "WorldPosition.h"
#include "GameFramework/Actor.h"

// Sets default values for this component's properties
UWorldPosition::UWorldPosition()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UWorldPosition::BeginPlay()
{
	Super::BeginPlay();
	
/* 	FString Log = TEXT("Hello!");
	UE_LOG(LogTemp, Warning, TEXT("%s"), *Log); 
	//The * operator on the FString is overloaded to retrn the pointer to TChar Array
*/
	FString ObjectName = GetOwner()->GetName();
	UE_LOG(LogTemp, Warning, TEXT("Object Name: %s"), *ObjectName);

	FVector Location = GetOwner()->GetActorLocation();
	UE_LOG(LogTemp, Warning, TEXT("Object \"%s\" Location: %s"), *ObjectName, *Location.ToString());	
}


// Called every frame
void UWorldPosition::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

