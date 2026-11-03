// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "Grabber.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class BUILDINGESCAPE_API UGrabber : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UGrabber();

	// Called when the game starts
	virtual void BeginPlay() override;

	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;
	
private:
	float Reach = 100.0f;
	FVector PlayerViewPointLocation;
	FRotator PlayerViewPointRotation;
	APlayerController* Owner;
	
	UPhysicsHandleComponent* PhysicsHandle = nullptr;
	UInputComponent* InputComponent = nullptr;

	// ray-cast and grab what is in reach
	void Grab();
	void Release();

	void UGrabber::FindPhysicsHandleComponent();
	void UGrabber::SetupInputComponent();
	const FHitResult UGrabber::GetFirstPhysicsBody();
	const FHitResult UGrabber::GetFirstDynamicBody();
	void UGrabber::MoveGrabbedObjectWithPlayer();
	FVector UGrabber::GetReachLineStart();
	FVector UGrabber::GetReachLineEnd();

	void Debug_DrawDebugLine();
};
