// Fill out your copyright notice in the Description page of Project Settings.

#include "DrawDebugHelpers.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "Components/InputComponent.h"
#include "Components/SphereComponent.h"
#include "Camera/CameraComponent.h"
#include "Math/UnrealMathUtility.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "Sound/SoundBase.h"
#include "Kismet/GameplayStatics.h"
#include "Tank.h"
#include "Projectile.h"
#include "GameFramework/SpringArmComponent.h"
#include "Tower.h"


ATower::ATower() {

	PrimaryActorTick.bCanEverTick = true; 

	MainComponent = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Root Capsule"));
	RootComponent = MainComponent;

	//MainCapsule = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Main Capsule"));
	//MainCapsule->SetupAttachment(MainComponent);

	//SecondaryCapsule = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Secondary Capsule"));
	//SecondaryCapsule->SetupAttachment(MainCapsule);

	TankMesh = CreateDefaultSubobject<UStaticMeshComponent>("TANK MESH");
	TankMesh->SetupAttachment(MainComponent);

	TankPrimaryMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Seconday Mesh"));
	TankPrimaryMesh->SetupAttachment(MainComponent);

	ProjectileSpawnPoint = CreateDefaultSubobject<USceneComponent>(TEXT("Projectile Spawn"));
	ProjectileSpawnPoint->SetupAttachment(TankPrimaryMesh);

	SphereCollider = CreateDefaultSubobject<USphereComponent>(TEXT("Collision Sphere"));
	SphereCollider->SetupAttachment(MainCapsule);


	

	//BoxCollider->SetupAttachment(MainCapsule); 

	
	
}

void ATower::BeginPlay() {
	Super::BeginPlay(); 

	

	FVector Location = GetActorLocation(); 

	float Radius = FireRange; 

	DrawDebugSphere(GetWorld(), Location, Radius, 30.f, FColor::Orange, true); 

	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	
	
	
}

void ATower::Tick(float DeltaTime) {

	Super::Tick(DeltaTime); 

	TowerAI(); 

	
}


void ATower::DebugMessage() {

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 15.f, FColor::Emerald, TEXT("TOWER CLASS IS WORKING")); 
	}
}


void ATower::Fire() {

	
	FVector Location = ProjectileSpawnPoint->GetComponentLocation();
	FRotator Rotation = ProjectileSpawnPoint->GetComponentRotation(); 


	GetWorld()->SpawnActor<AProjectile>(ProjectileClass, Location, Rotation); 

	UGameplayStatics::PlaySoundAtLocation(this, ProjectileSound, Location); 
	
}

void ATower::ProcedesToLineTrace() {

	FVector End = Tank->GetActorLocation(); 

	FVector Start = ProjectileSpawnPoint->GetComponentLocation();
	

	DrawDebugLine(GetWorld(), Start, End, FColor::Green);
}


void ATower::TowerAI() {

	if (Tank) {
		Distance = FVector::Dist(GetActorLocation(), Tank->GetActorLocation());
		ProcedesToLineTrace();

		if (Distance <= FireRange) {
			//RotateMyTurret();
			//Fire();
			RotateTurretAttack(Tank->GetActorLocation());
		}

		
	}
}


void ATower::RotateTurretAttack(FVector LookAtTarget) {

	FVector ToTarget = LookAtTarget - TankPrimaryMesh->GetComponentLocation();

	FRotator LookAtRotation = FRotator(0.f, ToTarget.Rotation().Yaw, 0.f);

	float Time = UGameplayStatics::GetWorldDeltaSeconds(this);
	float InterpSpeed = 25.f;


	TankPrimaryMesh->SetWorldRotation(FMath::RInterpTo(TankPrimaryMesh->GetComponentRotation(), LookAtRotation, Time, InterpSpeed));

	ProcedeToLineTraceByChannel(); 
}


void ATower::ProcedeToLineTraceByChannel() {

	FHitResult Hit; 
	FVector TraceStart = ProjectileSpawnPoint->GetComponentLocation(); 
	FVector TraceEnd =ProjectileSpawnPoint->GetComponentLocation() + ProjectileSpawnPoint->GetForwardVector() * FireRange; 

	FCollisionQueryParams QueryParams;
	QueryParams.AddIgnoredActor(this);

	GetWorld()->LineTraceSingleByChannel(Hit, TraceStart, TraceEnd, TraceChannelProperty, QueryParams);

	Fire(); 

	if (Hit.bBlockingHit && IsValid(Hit.GetActor()))
	{

		if (GEngine) {
			GEngine->AddOnScreenDebugMessage(-1, 10.f, FColor::Cyan, TEXT("Trace hit actor")); 
		}
		
	}
	else {
		UE_LOG(LogTemp, Log, TEXT("No Actors were hit"));
	}
	


}

