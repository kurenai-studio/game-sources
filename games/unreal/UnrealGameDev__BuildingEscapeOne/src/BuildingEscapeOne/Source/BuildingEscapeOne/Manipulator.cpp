// Fill out your copyright notice in the Description page of Project Settings.

#include "BuildingEscapeOne.h"
#include "Manipulator.h"
#include "Switchable.h"


// Sets default values for this component's properties
UManipulator::UManipulator()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UManipulator::BeginPlay()
{
	Super::BeginPlay();

	BindInputToActions();
	
}


// Called every frame
void UManipulator::TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction )
{
	Super::TickComponent( DeltaTime, TickType, ThisTickFunction );

	// ...
}


ReachLine UManipulator::GetReachLine()
{
	ReachLine ReachLine;
	FVector Position;
	FRotator Direction;
	GetWorld()->GetFirstPlayerController()->GetPlayerViewPoint(OUT Position, OUT Direction);
	ReachLine.End = Position + Direction.Vector() * ReachDistance;
	ReachLine.Start = Position;
	return ReachLine;
}

void UManipulator::BindInputToActions()
{
	UInputComponent* InputComponent = GetOwner()->FindComponentByClass<UInputComponent>();

	if (InputComponent)
	{
		InputComponent->BindAction(FName("Manipulate"), EInputEvent::IE_Pressed, this, &UManipulator::Manipulate);
		InputComponent->BindAction(FName("GameExit"), EInputEvent::IE_Pressed, this, &UManipulator::ExitGame);
	}
	else
	{
		UE_LOG(LogTemp, Error, TEXT("No InputComponent found for %s!"), *GetOwner()->GetName());
	}

}

void UManipulator::Manipulate()
{
	if (GetFirstPhysicsBodyInReach().GetActor())
	{
		USwitchable* Switchable = GetFirstPhysicsBodyInReach().GetActor()->FindComponentByClass<USwitchable>();
		if (Switchable)
		{
			Switchable->ChangeSwitchState();
		}
	}
}

FHitResult UManipulator::GetFirstPhysicsBodyInReach()
{
	// parameterised search for simpe collision ignoring us self
	FCollisionQueryParams QueryParameter(FName(TEXT("")), false, GetOwner());

	FHitResult HitResult; // output parameter
	GetWorld()->LineTraceSingleByObjectType(
		OUT HitResult,
		GetReachLine().Start,
		GetReachLine().End,
		FCollisionObjectQueryParams(ECollisionChannel::ECC_PhysicsBody),
		QueryParameter
	);

	return HitResult;
}

void UManipulator::ExitGame() 
{
	UE_LOG(LogTemp, Error, TEXT("Exiting the Game now!"));
	//FGenericPlatformMisc::RequestExit(true);
	GetWorld()->GetFirstPlayerController()->ConsoleCommand("quit");
}
