// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "Metronome.h"


// Sets default values for this component's properties
UMetronome::UMetronome()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UMetronome::BeginPlay()
{
	Super::BeginPlay();

	// ...

	AGGJ2017GameStateBase* GameState = Cast<AGGJ2017GameStateBase>(GetWorld()->GetGameState());
	EventManager = GameState->GlobalEventHandler;
}


// Called every frame
void UMetronome::TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction )
{
	Super::TickComponent( DeltaTime, TickType, ThisTickFunction );

	// ...
}


void UMetronome::Beat() {

	EventManager->OnBeatReceived.Broadcast();
}

