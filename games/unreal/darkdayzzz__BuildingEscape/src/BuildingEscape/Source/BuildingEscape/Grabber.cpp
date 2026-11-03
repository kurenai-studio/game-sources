// Fill out your copyright notice in the Description page of Project Settings.

#include "BuildingEscape.h"
#include "Grabber.h"
#include "InteractionType.h"
#include "OpenDoor.h"

#define OUT

// Sets default values for this component's properties
UGrabber::UGrabber()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	bWantsBeginPlay = true;
	PrimaryComponentTick.bCanEverTick = true;
}

// Called when the game starts
void UGrabber::BeginPlay()
{
	Super::BeginPlay();

	Owner = GetWorld()->GetFirstPlayerController();	
	FindPhysicsHandleComponent();
	SetupInputComponent();

}

/// look for attached input component
void UGrabber::SetupInputComponent()
{
	InputComponent = GetOwner()->FindComponentByClass<UInputComponent>();
	if (InputComponent) {
		InputComponent->BindAction("Grab", IE_Pressed, this, &UGrabber::Grab);
		InputComponent->BindAction("Grab", IE_Released, this, &UGrabber::Release);
	}
	else {
		UE_LOG(LogTemp, Error, TEXT("No input component found. Check object %s has input component."), *(GetOwner()->GetName()));
	}
}

/// look for attached physics handle
void UGrabber::FindPhysicsHandleComponent()
{
	PhysicsHandle = GetOwner()->FindComponentByClass<UPhysicsHandleComponent>();
	if (PhysicsHandle==nullptr)
	{
		UE_LOG(LogTemp, Error, TEXT("No physics handle found. Check object %s has physics handle component."), *(GetOwner()->GetName()));
	}
}

// try and reach any actors with physics body collision channel set
void UGrabber::Grab()
{
	if (!PhysicsHandle) { return; }
	auto HitResult = GetFirstPhysicsBody();
	auto ComponentToGrab = HitResult.GetComponent();
	auto ActorHit = HitResult.GetActor();
	/// if we hit something then attach a physics handle
	if (ActorHit) {
		PhysicsHandle->GrabComponent(
			ComponentToGrab,
			NAME_None,
			ComponentToGrab->GetOwner()->GetActorLocation(),
			true
		);
	} else {
		FHitResult HitResult = GetFirstDynamicBody();
		auto ActorHit = HitResult.GetActor();
		if (ActorHit) {
			UOpenDoor* OpenDoorComponent = ActorHit->FindComponentByClass<UOpenDoor>();
			if (OpenDoorComponent) {				
				UE_LOG(LogTemp, Warning, TEXT("Wiggling handle %s"), *(ActorHit->GetName()));
				if (OpenDoorComponent->DoorLocked) {
					UE_LOG(LogTemp, Warning, TEXT("%s locked!"), *(ActorHit->GetName()));
				}
				else {
					OpenDoorComponent->ManualOpen = true;
					if (OpenDoorComponent->DoorOpen) {
						UE_LOG(LogTemp, Warning, TEXT("Closing %s"), *(ActorHit->GetName()));
						OpenDoorComponent->CloseDoor();
					}
					else {
						UE_LOG(LogTemp, Warning, TEXT("Opening %s"), *(ActorHit->GetName()));
						OpenDoorComponent->OpenDoor();
					}
				}
			}
		}
	}
};

void UGrabber::Release()
{
	if (!PhysicsHandle) { return; }
	PhysicsHandle->ReleaseComponent();
};

// Called every frame
void UGrabber::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (!PhysicsHandle) { return; }
	if (PhysicsHandle->GrabbedComponent)
	{
		MoveGrabbedObjectWithPlayer();
	}
}

void UGrabber::MoveGrabbedObjectWithPlayer()
{
	if (!PhysicsHandle) { return; }
	Owner->GetPlayerViewPoint(
		OUT PlayerViewPointLocation,
		OUT PlayerViewPointRotation
	);
	FVector LineTraceEnd = PlayerViewPointLocation + PlayerViewPointRotation.Vector() * Reach;
	PhysicsHandle->SetTargetLocation(LineTraceEnd);
}

// Draw a debug line in bright red, 10cms thick
void UGrabber::Debug_DrawDebugLine()
{
	DrawDebugLine(
		GetWorld(),
		GetReachLineStart(),
		GetReachLineEnd(),
		FColor(255, 0, 0),
		false,
		0.f,
		0,
		10.f
	);
}

// get first physics body within reach
const FHitResult UGrabber::GetFirstPhysicsBody()
{
	/// get player location and direction and extrapolate reach direction	
	FCollisionQueryParams TraceParameters(FName(TEXT("")), false, GetOwner());
	FHitResult LineTraceHit;
	/// Check LINE-TRACE for hit results
	if (GetWorld()->LineTraceSingleByObjectType(
		OUT LineTraceHit,
		GetReachLineStart(),
		GetReachLineEnd(),
		FCollisionObjectQueryParams(ECollisionChannel::ECC_PhysicsBody),
		TraceParameters
	)) {
		AActor* ObjectHit = LineTraceHit.GetActor();
		UE_LOG(LogTemp, Warning, TEXT("Grabbing %s"), *(ObjectHit->GetName()));
	}
	return LineTraceHit;
}

// get first dynamic body within reach
const FHitResult UGrabber::GetFirstDynamicBody()
{
	/// get player location and direction and extrapolate reach direction	
	FCollisionQueryParams TraceParameters(FName(TEXT("")), false, GetOwner());
	FHitResult LineTraceHit;
	/// Check LINE-TRACE for hit results
	if (GetWorld()->LineTraceSingleByObjectType(
		OUT LineTraceHit,
		GetReachLineStart(),
		GetReachLineEnd(),
		FCollisionObjectQueryParams(ECollisionChannel::ECC_WorldDynamic),
		TraceParameters
	)) {
		AActor* ObjectHit = LineTraceHit.GetActor();
		UE_LOG(LogTemp, Warning, TEXT("Interacting with %s"), *(ObjectHit->GetName()));
	}
	return LineTraceHit;
}

FVector UGrabber::GetReachLineStart()
{
	Owner->GetPlayerViewPoint(
		OUT PlayerViewPointLocation,
		OUT PlayerViewPointRotation
	);
	return PlayerViewPointLocation;
}

FVector UGrabber::GetReachLineEnd()
{
	Owner->GetPlayerViewPoint(
		OUT PlayerViewPointLocation,
		OUT PlayerViewPointRotation
	);
	return PlayerViewPointLocation + PlayerViewPointRotation.Vector() * Reach;
}