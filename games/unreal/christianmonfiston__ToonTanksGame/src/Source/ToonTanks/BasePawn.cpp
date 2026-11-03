// Fill out your copyright notice in the Description page of Project Settings.


#include "Components/CapsuleComponent.h"
#include "Camera/CameraComponent.h"
#include "DrawDebugHelpers.h"
#include "BasePawn.h"

// Sets default values
ABasePawn::ABasePawn()
{
 	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void ABasePawn::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void ABasePawn::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	//DebugMessage();

}

// Called to bind functionality to input
void ABasePawn::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);


	
}

void ABasePawn::DebugMessage() {
	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 15.0f, FColor::Green, TEXT("Base Pawn Is working"));
	}
}

