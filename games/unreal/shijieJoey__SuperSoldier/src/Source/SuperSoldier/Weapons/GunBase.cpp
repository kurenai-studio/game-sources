// Fill out your copyright notice in the Description page of Project Settings.


#include "SuperSoldier/Weapons/GunBase.h"
#include "Components/SkeletalMeshComponent.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/Character.h"

// Sets default values
AGunBase::AGunBase()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false;
	InitializeComponents();
}

// Called when the game starts or when spawned
void AGunBase::BeginPlay()
{
	Super::BeginPlay();
}

// Called every frame
void AGunBase::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

void AGunBase::PullTrigger() 
{
	MuzzleAnimation();

	FHitResult HitResult;
	FVector ShootDirection;

	if (Aim(HitResult, ShootDirection))
	{
		ImpactAnimation(HitResult.Location, (-ShootDirection).Rotation());
		AActor* HitActor = HitResult.GetActor();
		if (!HitActor) return;
		AController* PlayerController = GetOwnerController();
		if (!PlayerController) return;
		HitActor->TakeDamage(
			Damage,
			FPointDamageEvent(Damage, HitResult, ShootDirection, nullptr),
			PlayerController,
			this
		);
	}
}

void AGunBase::SetActualMesh(class ACharacter* OwnerCharacter) 
{
	if (OriginGun && OwnerCharacter)
	{
		ActualMesh = OwnerCharacter->GetMesh();
	}
	else 
	{
		ActualMesh = Mesh;
	}
}

void AGunBase::InitializeComponents() 
{
	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);

	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Root);
}

void AGunBase::MuzzleAnimation() 
{
	if (MuzzleFlash)
	{
		UGameplayStatics::SpawnEmitterAttached(MuzzleFlash, ActualMesh, FName(*MuzzleSocketName));
	}
	if (MuzzleSound)
	{
		UGameplayStatics::SpawnSoundAttached(MuzzleSound, ActualMesh, FName(*MuzzleSocketName));
	}
}

void AGunBase::ImpactAnimation(FVector Location, FRotator Rotation) 
{
	if (ImpactEffect)
	{
		UGameplayStatics::SpawnEmitterAtLocation(GetWorld(), ImpactEffect, Location, Rotation);
	}
	if (ImpactSound)
	{
		UGameplayStatics::SpawnSoundAtLocation(GetWorld(), ImpactSound, Location, Rotation);
	}
}

bool AGunBase::Aim(FHitResult& HitResult, FVector& ShootDirection) 
{
	AController* PlayerController = GetOwnerController();
	if (!PlayerController) return false;

	FVector PlayerViewPointLocation;
	FRotator PlayerViewPointRotation;
	PlayerController->GetPlayerViewPoint(PlayerViewPointLocation, PlayerViewPointRotation);
	FVector EndLocation = PlayerViewPointLocation + PlayerViewPointRotation.Vector() * MaxShootRange;

	FCollisionQueryParams CollisionQueryParams;
	CollisionQueryParams.AddIgnoredActor(this);
	CollisionQueryParams.AddIgnoredActor(GetOwner());

	FVector MuzzleLocation = ActualMesh->GetSocketLocation(FName(*MuzzleSocketName));
	FHitResult HitResultFromViewPoint;
	bool bSucceeded = GetWorld()->LineTraceSingleByChannel(
		HitResultFromViewPoint,
		PlayerViewPointLocation,
		EndLocation,
		ECollisionChannel::ECC_EngineTraceChannel1,
		CollisionQueryParams
	);
	FVector ActualEndLocation;
	ActualEndLocation = bSucceeded ? HitResultFromViewPoint.Location : EndLocation;
	ShootDirection = (ActualEndLocation - MuzzleLocation).GetSafeNormal();
	return GetWorld()->LineTraceSingleByChannel(
		HitResult,
		MuzzleLocation,
		ActualEndLocation,
		ECollisionChannel::ECC_GameTraceChannel1,
		CollisionQueryParams
	);
}

AController* AGunBase::GetOwnerController() const
{
	APawn* Pawn = Cast<APawn>(GetOwner());
	if (!Pawn) return nullptr;
	return Pawn->GetController();
}

