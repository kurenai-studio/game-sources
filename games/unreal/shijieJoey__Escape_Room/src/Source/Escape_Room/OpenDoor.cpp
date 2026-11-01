// Copy Right Shijie Xiong


#include "OpenDoor.h"
#include "Components/AudioComponent.h"
#include "Components/PrimitiveComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "GameFramework/PlayerController.h"

#define OUT

// Sets default values for this component's properties
UOpenDoor::UOpenDoor()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
}


// Called when the game starts
void UOpenDoor::BeginPlay()
{
	Super::BeginPlay();

	SetupAudioComponent();
	SetupTriggerVolume();
	SetupDoorRotation();
}


// Called every frame
void UOpenDoor::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	DoorAction(DeltaTime);
}



void UOpenDoor::SetupAudioComponent()
{
	AudioComponent = GetOwner()->FindComponentByClass<UAudioComponent>();
	if (!AudioComponent)
	{
		UE_LOG(LogTemp, Error, TEXT("%s is missing Audio Component!"), *GetOwner()->GetName());
	}
}

void UOpenDoor::SetupTriggerVolume()
{
	if (!TriggerVolume)
	{
		UE_LOG(LogTemp, Error, TEXT("%s is missing Trigger Volume!"), *GetOwner()->GetName());
	}
}

void UOpenDoor::SetupDoorRotation()
{
	CurrentRotationYaw = InitialRotationYaw = GetOwner()->GetActorRotation().Yaw;
	TargetRotationYaw = InitialRotationYaw + DoorOpenRotationYaw;
}

float UOpenDoor::GetTotalMassOfActors() const
{
	if (!TriggerVolume)
	{
		return 0.f;
	}
	
	float CurrentTotalMass = 0.f;
	
	TArray<AActor*> OverlappingActors;

	TriggerVolume->GetOverlappingActors(OUT OverlappingActors);

	for (AActor* Actor : OverlappingActors)
	{
		CurrentTotalMass += Actor->FindComponentByClass<UPrimitiveComponent>()->GetMass();
	}

	return CurrentTotalMass;
}

void UOpenDoor::DoorAction(float DeltaTime)
{
	float CurrentTotalMass = GetTotalMassOfActors();

	if (CurrentTotalMass >= MinMassRequired && CurrentTotalMass <= MaxMassRequired)
	{
		OpenDoor(DeltaTime);
		DoorLastOpened = GetWorld()->GetTimeSeconds();
	}
	else if (GetWorld()->GetTimeSeconds() - DoorLastOpened > DoorCloseDelay) 
	{
		CloseDoor(DeltaTime);
	}
}

void UOpenDoor::OpenDoor(float DeltaTime)
{
	CurrentRotationYaw = FMath::FInterpTo(CurrentRotationYaw, TargetRotationYaw, DeltaTime, DoorOpenSpeed);
	FRotator CurrentDoorRotation = GetOwner()->GetActorRotation();
	CurrentDoorRotation.Yaw = CurrentRotationYaw;
	GetOwner()->SetActorRotation(CurrentDoorRotation);

	if (AudioComponent && !DoorOpend)
	{
		AudioComponent->Play();
		DoorOpend = true;
		DoorClosed = false;
	}
}

void UOpenDoor::CloseDoor(float DeltaTime)
{
	CurrentRotationYaw = FMath::FInterpTo(CurrentRotationYaw, InitialRotationYaw, DeltaTime, DoorCloseSpeed);
	FRotator CurrentDoorRotation = GetOwner()->GetActorRotation();
	CurrentDoorRotation.Yaw = CurrentRotationYaw;
	GetOwner()->SetActorRotation(CurrentDoorRotation);

	if (AudioComponent && !DoorClosed)
	{
		AudioComponent->Play();
		DoorOpend = false;
		DoorClosed = true;
	}
}

