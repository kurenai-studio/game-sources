#include "Enemies/SeagullPoisonZone.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Components/SphereComponent.h"
#include "SeagullStorm.h"
#include "Core/SeagullTypes.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"

ASeagullPoisonZone::ASeagullPoisonZone()
{
	PrimaryActorTick.bCanEverTick = true;
	Tags.Add(TEXT("Enemy"));

	DamageZone = CreateDefaultSubobject<USphereComponent>(TEXT("DamageZone"));
	DamageZone->SetSphereRadius(40.f);
	DamageZone->SetCollisionProfileName(TEXT("OverlapAllDynamic"));
	DamageZone->SetGenerateOverlapEvents(true);
	RootComponent = DamageZone;
	UStaticMeshComponent* Warning = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("PoisonWarning"));
	Warning->SetupAttachment(RootComponent);
	Warning->SetStaticMesh(LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder")));
	Warning->SetRelativeScale3D(FVector(0.8f, 0.8f, 0.01f));
	Warning->SetRelativeLocation(FVector(0.f, 0.f, -1.f));
	Warning->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	if (UMaterialInterface* Base = LoadObject<UMaterialInterface>(nullptr, TEXT("/Game/Materials/M_ArenaColor")))
	{
		UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(Base, this);
		Material->SetVectorParameterValue(TEXT("Color"), SeagullColors::JellyPurple);
		Warning->SetMaterial(0, Material);
	}
}

void ASeagullPoisonZone::BeginPlay()
{
	Super::BeginPlay();
	SetLifeSpan(Lifetime);
}

void ASeagullPoisonZone::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	DamageTimer -= DeltaTime;
	if (DamageTimer <= 0.f)
	{
		DamageTimer = DamageInterval;

		TArray<AActor*> Overlapping;
		DamageZone->GetOverlappingActors(Overlapping, ASeagullPlayerPawn::StaticClass());
		for (AActor* Actor : Overlapping)
		{
			ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(Actor);
			if (Player && Player->HealthComponent)
			{
				Player->HealthComponent->TakeDamage(DamagePerTick);
			}
		}
	}
}
