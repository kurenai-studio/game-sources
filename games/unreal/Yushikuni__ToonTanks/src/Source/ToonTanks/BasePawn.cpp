 // Fill out your copyright notice in the Description page of Project Settings.


#include "BasePawn.h"

#include "Kismet/GameplayStatics.h"
#include "Projectile.h"
#include "Particles/ParticleSystem.h"

// Sets default values
ABasePawn::ABasePawn()
{
 	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	// Making capsule component for collision
	CapsuleComp = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Capsule Collider"));
	
	// Capsule component is a root component
	RootComponent = CapsuleComp;

	//Adding meshes and attachet them
	BaseMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Base Mesh"));
	BaseMesh->SetupAttachment(CapsuleComp);

	TurretMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Turret Mesh"));
	TurretMesh->SetupAttachment(BaseMesh);

	ProjectileSpawnPoint = CreateDefaultSubobject<USceneComponent>(TEXT("Projectile Base"));
	ProjectileSpawnPoint->SetupAttachment(TurretMesh);


}

void ABasePawn::HandleDestruction()
{
	if (DeathParticles)
	{
		UGameplayStatics::SpawnEmitterAtLocation(this, DeathParticles, GetActorLocation(), GetActorRotation());
	}
	if (DeathSound)
	{
		UGameplayStatics::PlaySoundAtLocation(this, DeathSound, GetActorLocation());
	}
	if(PawnDeathCameraShake)
	{
		GetWorld()->GetFirstPlayerController()->ClientStartCameraShake(PawnDeathCameraShake);
	}
}

void ABasePawn::RotateTurret(FVector LookAtTarget)
{
	FVector ToTarget = LookAtTarget - TurretMesh->GetComponentLocation(); //World space vector
	FRotator LookAtRotation = FRotator(0.f, ToTarget.Rotation().Yaw, 0.f); //world space rotation

	TurretMesh->SetWorldRotation(FMath::RInterpTo(TurretMesh->GetComponentRotation(),LookAtRotation,UGameplayStatics::GetWorldDeltaSeconds(this),25.f));
}

void ABasePawn::Fire()
{
	UE_LOG(LogTemp, Error, TEXT("FIRE!!!"));

	FRotator Rotation = ProjectileSpawnPoint->GetComponentRotation();
	FVector Location = ProjectileSpawnPoint->GetComponentLocation();
	if (!ProjectileClass)
	{
		UE_LOG(LogTemp, Error, TEXT("ProjectileClass is null!"));
		return;
	}
	UE_LOG(LogTemp, Warning, TEXT("ProjectileClass is NOT null!"));
	if (!ProjectileSpawnPoint)
	{
		UE_LOG(LogTemp, Error, TEXT("ProjectileSpawnPoint is null!"));
		return;
	}
	UE_LOG(LogTemp, Warning, TEXT("ProjectileSpawnPoint NOT null!"));
	if (!GetWorld())
	{
		UE_LOG(LogTemp, Error, TEXT("GetWorld() returned null!"));
		return;
	}
	UE_LOG(LogTemp, Warning, TEXT("GetWorld() NOT null!"));

	AProjectile* Projectile = GetWorld()->SpawnActor<AProjectile>(ProjectileClass, Location, Rotation);
	if (IsValid(Projectile))
	{
		UE_LOG(LogTemp, Warning, TEXT("Projectile IS VALID!"));
		Projectile->SetOwner(this);
		
	}
	else
	{
		UE_LOG(LogTemp, Error, TEXT("Projectile IS NOT VALID!"));
		return;
	}
	
	
}