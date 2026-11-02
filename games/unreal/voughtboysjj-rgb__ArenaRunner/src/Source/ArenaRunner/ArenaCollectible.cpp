// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaCollectible.h"

#include "ArenaCharacter.h"
#include "ArenaGameMode.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

AArenaCollectible::AArenaCollectible()
{
	PrimaryActorTick.bCanEverTick = true;

	Sphere = CreateDefaultSubobject<USphereComponent>(TEXT("Sphere"));
	Sphere->InitSphereRadius(95.f);
	Sphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Sphere->SetCollisionResponseToAllChannels(ECR_Ignore);
	Sphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	Sphere->SetGenerateOverlapEvents(true);
	RootComponent = Sphere;

	static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));

	GemMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("GemMesh"));
	GemMesh->SetupAttachment(Sphere);
	GemMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	GemMesh->SetGenerateOverlapEvents(false);
	GemMesh->SetRelativeScale3D(FVector(0.55f));
	if (SphereMesh.Succeeded())
	{
		GemMesh->SetStaticMesh(SphereMesh.Object);
	}

	HaloMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("HaloMesh"));
	HaloMesh->SetupAttachment(Sphere);
	HaloMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	HaloMesh->SetGenerateOverlapEvents(false);
	HaloMesh->SetRelativeRotation(FRotator(90.f, 0.f, 0.f));
	HaloMesh->SetRelativeScale3D(FVector(0.95f, 0.95f, 0.02f));
	if (CylinderMesh.Succeeded())
	{
		HaloMesh->SetStaticMesh(CylinderMesh.Object);
	}
}

void AArenaCollectible::BeginPlay()
{
	Super::BeginPlay();

	StartLocation = GetActorLocation();
	Elapsed = 0.f;

	Sphere->OnComponentBeginOverlap.AddDynamic(this, &AArenaCollectible::OnSphereOverlap);

	if (UMaterialInterface* BaseMaterial = GemMesh ? GemMesh->GetMaterial(0) : nullptr)
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.05f, 0.95f, 0.85f));
			MID->SetVectorParameterValue(TEXT("EmissiveColor"), FLinearColor(0.05f, 0.95f, 0.85f));
			GemMesh->SetMaterial(0, MID);
		}
	}

	if (UMaterialInterface* BaseMaterial = HaloMesh ? HaloMesh->GetMaterial(0) : nullptr)
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.6f, 1.f, 1.f));
			MID->SetVectorParameterValue(TEXT("EmissiveColor"), FLinearColor(0.6f, 1.f, 1.f));
			HaloMesh->SetMaterial(0, MID);
		}
	}
}

void AArenaCollectible::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	Elapsed += DeltaSeconds;

	const float Bob = FMath::Sin(Elapsed * BobSpeed + OrbitPhase) * BobHeight;
	SetActorLocation(StartLocation + FVector(0.f, 0.f, Bob));

	if (GemMesh)
	{
		GemMesh->AddLocalRotation(FRotator(0.f, SpinSpeed * DeltaSeconds, 25.f * DeltaSeconds));
	}

	if (HaloMesh)
	{
		HaloMesh->AddLocalRotation(FRotator(0.f, 0.f, 120.f * DeltaSeconds));
	}
}

void AArenaCollectible::OnSphereOverlap(UPrimitiveComponent* /*OverlappedComponent*/, AActor* OtherActor,
	UPrimitiveComponent* /*OtherComp*/, int32 /*OtherBodyIndex*/, bool /*bFromSweep*/,
	const FHitResult& /*SweepResult*/)
{
	if (bCollected)
	{
		return;
	}

	AArenaCharacter* Character = Cast<AArenaCharacter>(OtherActor);
	if (!Character || Character->IsDead())
	{
		return;
	}

	bCollected = true;
	SetActorEnableCollision(false);

	if (OwningGameMode)
	{
		OwningGameMode->HandleCollectibleCollected(this);
	}
	else
	{
		Destroy();
	}
}
