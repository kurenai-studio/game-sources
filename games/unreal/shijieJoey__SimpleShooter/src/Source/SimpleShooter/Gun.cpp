// Fill out your copyright notice in the Description page of Project Settings.


#include "Gun.h"
#include "Components/SkeletalMeshComponent.h"
#include "Kismet/GameplayStatics.h"
#include "DrawDebugHelpers.h"

// Sets default values
AGun::AGun()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	SetupComponents();
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

}

void AGun::PullTrigger() 
{
	UGameplayStatics::SpawnEmitterAttached(MuzzleFlash, Mesh, TEXT("MuzzleFlashSocket"));
	UGameplayStatics::SpawnSoundAttached(MuzzleSound, Mesh, TEXT("MuzzleFlashSocket"));

	FHitResult HitResult;
	FVector ShotDirection;
	if (GunTrace(HitResult, ShotDirection)) 
	{
		UGameplayStatics::SpawnEmitterAtLocation(GetWorld(), ImpactEffect, HitResult.Location, ShotDirection.Rotation());
		UGameplayStatics::SpawnSoundAtLocation(GetWorld(), ImpactSound, HitResult.Location, ShotDirection.Rotation());
		AActor* HitActor = HitResult.GetActor();
		if (HitActor)
		{
			AController* PlayerController = GetOwnerController();
			if (!PlayerController) return;
			HitActor->TakeDamage(Damage, 
			FPointDamageEvent(Damage, HitResult, -ShotDirection, nullptr), 
			PlayerController,
			this
			);
		}
	}
	
}

void AGun::SetupComponents() 
{
	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);

	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("Mesh"));
	Mesh->SetupAttachment(Root);
}

bool AGun::GunTrace(FHitResult& Hit, FVector& ShotDirection) 
{
	AController* PlayerController = GetOwnerController();
	if (!PlayerController) return false;
	FVector PlayerViewPointLocation;
	FRotator PlayerViewPointRotation;
	PlayerController->GetPlayerViewPoint(PlayerViewPointLocation, PlayerViewPointRotation);
	ShotDirection = - PlayerViewPointRotation.Vector();

	FVector Target = PlayerViewPointLocation + PlayerViewPointRotation.Vector() * MaxShootRange;
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(this);
	Params.AddIgnoredActor(GetOwner());
	return GetWorld()->LineTraceSingleByChannel(Hit, PlayerViewPointLocation, Target, ECollisionChannel::ECC_GameTraceChannel1, Params);
}

AController* AGun::GetOwnerController() const
{
	APawn* PlayerPawn = Cast<APawn>(GetOwner());
	if (!PlayerPawn) return nullptr;
	return PlayerPawn->GetController();
}
