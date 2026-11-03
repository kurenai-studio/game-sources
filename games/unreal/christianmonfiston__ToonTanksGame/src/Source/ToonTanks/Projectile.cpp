// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Components/PrimitiveComponent.h"
#include "Components/InputComponent.h"
#include "Components/SphereComponent.h"
#include "Components/BoxComponent.h"
#include "Sound/SoundBase.h"
#include "Particles/ParticleSystem.h"
#include "Kismet/GameplayStatics.h"
#include "Camera/CameraComponent.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/SpringArmComponent.h"
#include "DrawDebugHelpers.h"
#include "Projectile.h"

// Sets default values
AProjectile::AProjectile()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	
	
	

	ProjectileMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Static Mesh")); 
	RootComponent = ProjectileMesh;

	ProjectileMovement = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("Projectile Comp"));

	Time = UGameplayStatics::GetWorldDeltaSeconds(this);

	ProjectileMovement->InitialSpeed = 2000.f * Time; 
	ProjectileMovement->MaxSpeed = 2000.f * Time; 

	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("Collision Box")); 

	BoxComponent->SetupAttachment(ProjectileMesh); 

	
	

	
}

// Called when the game starts or when spawned
void AProjectile::BeginPlay()
{
	Super::BeginPlay();

 

	ProjectileMesh->OnComponentHit.AddDynamic(this, &AProjectile::OnHit); 
	
	
	
}

// Called every frame
void AProjectile::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	FVector Location = GetActorLocation(); 

	if (Projectile) {
		UGameplayStatics::SpawnEmitterAtLocation(this, ProjectileTrailEmitter, Location);
	}
}

void AProjectile::Testing() {

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 15.f, FColor::Purple, TEXT("SUCCESFULLy CALLING TESTING FROM TANK")); 
	}

}

void AProjectile::ShootProjectile() {

	FVector ActorLocation = GetActorLocation(); 
	FRotator ActorRotation = GetActorRotation(); 
	

	

}


void AProjectile::OnHit(UPrimitiveComponent* HitComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, FVector NormalImpulse, const FHitResult& Hit) {

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 15.f, FColor::Magenta, TEXT("On Hit"));
	}



	Destroy(); 
}
	

