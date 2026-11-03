// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "Manipulator.generated.h"

// Returnvalue for LineTracing
struct ReachLine
{
	FVector Start;
	FVector End;
};

UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class BUILDINGESCAPEONE_API UManipulator : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UManipulator();

	// Called when the game starts
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;

private:
	// Distance for LineTracing
	float ReachDistance = 100.f;

	// LineTrace from Actor viewpoint 
	ReachLine GetReachLine();

	// Find the input component and bind it witch actions
	void BindInputToActions();
	
	// Action for manipulate input
	void Manipulate();

	// Helper funktion to determine the manipulatable actor
	FHitResult GetFirstPhysicsBodyInReach();

	// Just a hack to exit the game by keypress
	void ExitGame();
	
};
