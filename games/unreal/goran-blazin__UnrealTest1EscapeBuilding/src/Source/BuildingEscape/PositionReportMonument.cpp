// Fill out your copyright notice in the Description page of Project Settings.

#include "PositionReportMonument.h"
#include "Gameframework/Actor.h"

// Sets default values for this component's properties
UPositionReportMonument::UPositionReportMonument()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UPositionReportMonument::BeginPlay()
{
	Super::BeginPlay();
	FString ObjectName = GetOwner()->GetName();

    UE_LOG(LogTemp, Error, TEXT("Position report on %s ready!!"), *ObjectName);
	
}


// Called every frame
void UPositionReportMonument::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

