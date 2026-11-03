// Fill out your copyright notice in the Description page of Project Settings.

#include "BuildingEscapeOne.h"
#include "Switchable.h"


// Sets default values for this component's properties
USwitchable::USwitchable()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void USwitchable::BeginPlay()
{
	Super::BeginPlay();

	// ...
	
}


// Called every frame
void USwitchable::TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction )
{
	Super::TickComponent( DeltaTime, TickType, ThisTickFunction );

	// ...
}

void USwitchable::ChangeSwitchState()
{
	// Alternate the state of the Switch
	SwitchState = !SwitchState;
	SwitchEvent.Broadcast(GetOwner(), SwitchState);
}

void USwitchable::SetSwitchState(bool State)
{
	SwitchState = State;
	SwitchEvent.Broadcast(GetOwner(), SwitchState);
}

