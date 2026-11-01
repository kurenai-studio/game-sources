// Fill out your copyright notice in the Description page of Project Settings.


#include "UnrealEngineLearning/Guns/Gun.h"

#include "Projectile.h"
#include "ToolMenusLog.h"
#include "Kismet/GameplayStatics.h"

// Sets default values
AGun::AGun()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	GunMesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("GunMesh"));
	GunMesh->SetupAttachment(RootComponent);
}

void AGun::BeginFiring()
{
	IsFiring = true;
}

void AGun::EndFiring()
{
	IsFiring = false;
}


// Called when the game starts or when spawned
void AGun::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame

void AGun::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (IsFiring)
	{
		float FireInterval = 60.f / RateOfFire;
		float CurrentTime = GetWorld()->GetTimeSeconds();

		if (CurrentTime - LastFireTime >= FireInterval)
		{
			Fire();
			LastFireTime = CurrentTime;
		}
	}
}

void AGun::Fire()
{
	UE_LOG(LogTemp, Log, TEXT("%s fired."), *GetName());

	if (FireSound)
	{
		UGameplayStatics::PlaySoundAtLocation(this, FireSound, GetActorLocation());
	}

	if (ProjectileClass && GunMesh)
	{
		FVector MuzzleLocation = GunMesh->GetSocketLocation("Muzzle");
		FRotator MuzzleRotation = GunMesh->GetSocketRotation("Muzzle");

		FActorSpawnParameters SpawnParams;
		SpawnParams.Owner = this;
		SpawnParams.Instigator = GetInstigator();

		AProjectile* Projectile = GetWorld()->SpawnActor<AProjectile>(
			ProjectileClass,
			MuzzleLocation,
			MuzzleRotation,
			SpawnParams
		);

		//if (Projectile)
		//{
		//
		//}
	}
}

