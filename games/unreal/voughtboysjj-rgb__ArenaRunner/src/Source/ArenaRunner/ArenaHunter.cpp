// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaHunter.h"

#include "ArenaCharacter.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "GameFramework/DamageType.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

AArenaHunter::AArenaHunter()
{
	PrimaryActorTick.bCanEverTick = true;

	Sphere = CreateDefaultSubobject<USphereComponent>(TEXT("Sphere"));
	Sphere->InitSphereRadius(70.f);
	Sphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Sphere->SetCollisionResponseToAllChannels(ECR_Ignore);
	Sphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	// Block world geometry so the sweep below can stop hunters at walls and pylons.
	Sphere->SetCollisionResponseToChannel(ECC_WorldStatic, ECR_Block);
	Sphere->SetGenerateOverlapEvents(true);
	RootComponent = Sphere;

	static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));

	CoreMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("CoreMesh"));
	CoreMesh->SetupAttachment(Sphere);
	CoreMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	CoreMesh->SetGenerateOverlapEvents(false);
	CoreMesh->SetRelativeScale3D(FVector(0.85f));
	if (SphereMesh.Succeeded())
	{
		CoreMesh->SetStaticMesh(SphereMesh.Object);
	}

	RingMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("RingMesh"));
	RingMesh->SetupAttachment(Sphere);
	RingMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	RingMesh->SetGenerateOverlapEvents(false);
	RingMesh->SetRelativeRotation(FRotator(90.f, 0.f, 0.f));
	RingMesh->SetRelativeScale3D(FVector(1.35f, 1.35f, 0.03f));
	if (CylinderMesh.Succeeded())
	{
		RingMesh->SetStaticMesh(CylinderMesh.Object);
	}
}

void AArenaHunter::BeginPlay()
{
	Super::BeginPlay();

	Elapsed = 0.f;
	BaseZ = GetActorLocation().Z;

	Sphere->OnComponentBeginOverlap.AddDynamic(this, &AArenaHunter::OnSphereOverlap);

	if (UMaterialInterface* BaseMaterial = CoreMesh ? CoreMesh->GetMaterial(0) : nullptr)
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.95f, 0.12f, 0.08f));
			CoreMesh->SetMaterial(0, MID);
		}
	}

	if (UMaterialInterface* BaseMaterial = RingMesh ? RingMesh->GetMaterial(0) : nullptr)
	{
		if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, this))
		{
			MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(1.f, 0.55f, 0.15f));
			RingMesh->SetMaterial(0, MID);
		}
	}
}

void AArenaHunter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	Elapsed += DeltaSeconds;

	if (RingMesh)
	{
		RingMesh->AddLocalRotation(FRotator(0.f, 0.f, 260.f * DeltaSeconds));
	}

	AActor* TargetActor = Target.Get();
	if (!TargetActor)
	{
		return;
	}

	FVector MyLocation = GetActorLocation();
	FVector Delta = TargetActor->GetActorLocation() - MyLocation;
	Delta.Z = 0.f;

	const float Distance = Delta.Size();
	if (Distance > KINDA_SMALL_NUMBER)
	{
		const FVector Step = (Delta / Distance) * ChaseSpeed * DeltaSeconds;

		// Sweep so hunters never tunnel through the arena walls or the pylons.
		if (AddActorWorldOffset(Step, true))
		{
			// Blocked: try to slide around the obstacle instead of grinding into it.
			static const float AvoidanceAngles[] = { 35.f, -35.f, 70.f, -70.f, 110.f, -110.f };
			for (const float Angle : AvoidanceAngles)
			{
				const FVector Alternative = Step.RotateAngleAxis(Angle, FVector::UpVector);
				if (!AddActorWorldOffset(Alternative, true))
				{
					break;
				}
			}
		}
	}

	MyLocation = GetActorLocation();
	const float Bob = FMath::Sin(Elapsed * 2.4f) * BobAmplitude;
	SetActorLocation(FVector(MyLocation.X, MyLocation.Y, BaseZ + Bob), false);
}

void AArenaHunter::OnSphereOverlap(UPrimitiveComponent* /*OverlappedComponent*/, AActor* OtherActor,
	UPrimitiveComponent* /*OtherComp*/, int32 /*OtherBodyIndex*/, bool /*bFromSweep*/,
	const FHitResult& /*SweepResult*/)
{
	AArenaCharacter* Character = Cast<AArenaCharacter>(OtherActor);
	if (!Character || Character->IsDead())
	{
		return;
	}

	UGameplayStatics::ApplyDamage(Character, ContactDamage, nullptr, this, UDamageType::StaticClass());
}
