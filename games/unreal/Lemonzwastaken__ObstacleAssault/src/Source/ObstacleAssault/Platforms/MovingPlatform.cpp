// Fill out your copyright notice in the Description page of Project Settings.


#include "Platforms/MovingPlatform.h"

// Sets default values
AMovingPlatform::AMovingPlatform()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void AMovingPlatform::BeginPlay()
{
	Super::BeginPlay();

	//Get Start Location
	StartLocation = GetActorLocation();
}

// Called every frame
void AMovingPlatform::Tick(float DeltaTime)
{

	Super::Tick(DeltaTime);

	MovePlatform(DeltaTime);
	RotatePlatform(DeltaTime);

}


//Platform Movement

float AMovingPlatform::GetDistanceMoved()
{
	return FVector::Dist(StartLocation, GetActorLocation());
}


void AMovingPlatform::MovePlatform(float DeltaTime)
{
	// Moves the platform by a set velocity in Delta Time
	DistanceMoved = GetDistanceMoved();

	if (DistanceMoved >= MoveDistance) 
	{
		FVector MoveDirection = PlatformVelocity.GetSafeNormal();
		FVector NewStartLocation = StartLocation + (MoveDirection * MoveDistance);
		SetActorLocation(NewStartLocation);
		StartLocation = NewStartLocation;

		PlatformVelocity = -PlatformVelocity;
	}
	else 
	{
		FVector CurrentLocation = GetActorLocation();
		CurrentLocation = CurrentLocation + (PlatformVelocity * DeltaTime);
		SetActorLocation(CurrentLocation);
	}

}
void AMovingPlatform::RotatePlatform(float DeltaTime)
{
	//Rotates platform by delta time

	FRotator RotationToAdd = RotationVelocity * DeltaTime;
	AddActorLocalRotation(RotationVelocity);


}
