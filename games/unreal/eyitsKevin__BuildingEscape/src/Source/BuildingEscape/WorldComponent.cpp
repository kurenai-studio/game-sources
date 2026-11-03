// Copyright Kevin Luu 2020

#include "WorldComponent.h"
#include "GameFramework/Actor.h"

// Sets default values for this component's properties
UWorldComponent::UWorldComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	// ...
}

// Called when the game starts
void UWorldComponent::BeginPlay()
{
	Super::BeginPlay();

	const FString ActorName = GetOwner()->GetName();
	const FVector ActorPosition = GetOwner()->GetActorLocation();
	
	UE_LOG(LogTemp, Warning, TEXT("%s"), *ActorName);
	UE_LOG(LogTemp, Warning, TEXT("It's position is: %s"), *ActorPosition.ToString());
	UE_LOG(LogTemp, Display, TEXT("Starting the world component"));
}

// Called every frame
void UWorldComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}