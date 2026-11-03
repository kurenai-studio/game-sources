// Copyright Artur Symanovic 2020


#include "OpenDoor.h"
#include "GameFramework/Actor.h"

// Sets default values for this component's properties
UOpenDoor::UOpenDoor()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UOpenDoor::BeginPlay()
{
	Super::BeginPlay();	
	InitialYaw = GetOwner()->GetActorRotation().Yaw;
	if (PressurePlate == NULL)
	{
		UE_LOG(	
				LogTemp,
				Error,
				TEXT("%s has an open door component but no pressure plate assigned to it"),
				*GetOwner()->GetName());
	}

	ActorThatOpen = GetWorld()->GetFirstPlayerController()->GetPawn();
}


// Called every frame
void UOpenDoor::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (PressurePlate==NULL || ActorThatOpen==NULL) return;
	if (PressurePlate->IsOverlappingActor(ActorThatOpen))
	{
		OpenDoor(DeltaTime);
		DoorLastOpened = GetWorld()->GetTimeSeconds();
	}else
	{	
		if (GetWorld()->GetTimeSeconds() - DoorLastOpened > DoorCloseDelay)
		{
			CloseDoor(DeltaTime);
		}
	}
	
}

void UOpenDoor::OpenDoor(float DeltaTime)
{
	FRotator CurrentDoorRotation = GetOwner()->GetActorRotation();
	FRotator NextDoorRotation = FRotator(CurrentDoorRotation);
	float YawStep = FMath::FInterpTo(CurrentDoorRotation.Yaw, TargetYaw, DeltaTime, 1);
	NextDoorRotation.Yaw = YawStep;
	//UE_LOG(LogTemp, Warning, TEXT("CurrentDoorRotation Yaw: %f"), CurrentDoorRotation.Yaw);
	//UE_LOG(LogTemp, Warning, TEXT("NextDoorRotation Yaw: %f"), NextDoorRotation.Yaw);	
	GetOwner()->SetActorRotation(NextDoorRotation);		
}

void UOpenDoor::CloseDoor(float DeltaTime)
{
	FRotator CurrentDoorRotation = GetOwner()->GetActorRotation();
	FRotator NextDoorRotation = FRotator(CurrentDoorRotation);
	float YawStep = FMath::FInterpTo(CurrentDoorRotation.Yaw, InitialYaw, DeltaTime, 1);
	NextDoorRotation.Yaw = YawStep;
	//UE_LOG(LogTemp, Warning, TEXT("CurrentDoorRotation Yaw: %f"), CurrentDoorRotation.Yaw);
	//UE_LOG(LogTemp, Warning, TEXT("NextDoorRotation Yaw: %f"), NextDoorRotation.Yaw);	
	GetOwner()->SetActorRotation(NextDoorRotation);			
}


