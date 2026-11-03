// Copyright Kevin Luu 2021


#include "OpenDoorComponent.h"
#include "GameFramework/Actor.h"

// Sets default values for this component's properties
UOpenDoorComponent::UOpenDoorComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}

void UOpenDoorComponent::HandleOpenDoor()
{
	CurrentYaw = FMath::Lerp(CurrentYaw, TargetYaw, 0.01f);
	GetOwner()->SetActorRotation(FRotator(0.0f, CurrentYaw, 0.0f));
}

void UOpenDoorComponent::HandleCloseDoor() const
{
	GetOwner()->SetActorRotation(InitialRotation);
}


// Called when the game starts
void UOpenDoorComponent::BeginPlay()
{
	Super::BeginPlay();
	InitialRotation = GetOwner()->GetActorRotation();
	StartingYaw = InitialRotation.Yaw;
	CurrentYaw = StartingYaw;
	TargetYaw = 90.0f;
}




// Called every frame
void UOpenDoorComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	UE_LOG(LogTemp, Warning, TEXT("%f"), GetOwner()->GetActorRotation().Yaw);
	HandleOpenDoor();
}

