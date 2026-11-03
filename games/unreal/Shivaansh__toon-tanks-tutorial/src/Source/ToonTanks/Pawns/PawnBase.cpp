// Fill out your copyright notice in the Description page of Project Settings.


#include "PawnBase.h"
#include "Components/CapsuleComponent.h"
// Sets default values
APawnBase::APawnBase()
{
 	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	
	CapsuleComp = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Capsule Component"));
	//set as root component in hierarchy
	RootComponent = CapsuleComp;
	
	BodyBaseMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Base Mesh"));
	BodyBaseMesh->SetupAttachment(RootComponent);

	BodyTurretMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Turret Mesh"));
	BodyTurretMesh->SetupAttachment(BodyBaseMesh);

	ProjectileSpawnPosition = CreateDefaultSubobject<USceneComponent>("Projectile Spawn Position");
	ProjectileSpawnPosition->SetupAttachment(BodyTurretMesh);	
}


void APawnBase::RotateTurret(FVector TargetLocation) 
{
	FVector Target = FVector(TargetLocation.X, TargetLocation.X, BodyTurretMesh->GetComponentLocation().Z);
	FVector TurretLocation = BodyTurretMesh->GetComponentLocation();

	FVector Difference = FVector(Target- TurretLocation);
	FRotator TurretRotation = Difference.Rotation();
	// UE_LOG(LogTemp, Warning, TEXT("Difference - X: %f, Y: %f, Z: %f"), Difference.X, Difference.Y, Difference.Z);
	// Difference is zero along Z axis
	// UE_LOG(LogTemp, Warning, TEXT("Rotator - Pitch: %f, Yaw: %f, Roll: %f"), TurretRotation.Pitch, TurretRotation.Yaw, TurretRotation.Roll);
	BodyTurretMesh->SetWorldRotation(TurretRotation);
}

void APawnBase::Fire() 
{
	UE_LOG(LogTemp, Warning, TEXT("Fire - Base Class"));
}

void APawnBase::HandleDestruction() 
{
	
}
