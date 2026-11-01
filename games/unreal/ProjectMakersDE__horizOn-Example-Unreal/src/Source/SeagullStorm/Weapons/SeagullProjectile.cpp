#include "Weapons/SeagullProjectile.h"
#include "Animation/SeagullSpritePlane.h"
#include "Enemies/SeagullEnemyBase.h"
#include "Core/SeagullTypes.h"
#include "Components/SphereComponent.h"
#include "PaperFlipbook.h"
#include "PaperFlipbookComponent.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "SeagullStorm.h"

ASeagullProjectile::ASeagullProjectile()
{
	PrimaryActorTick.bCanEverTick = false;
	Tags.Add(TEXT("Projectile"));

	CollisionComponent = CreateDefaultSubobject<USphereComponent>(TEXT("Collision"));
	CollisionComponent->SetSphereRadius(8.f);
	CollisionComponent->SetCollisionProfileName(TEXT("OverlapAllDynamic"));
	CollisionComponent->SetGenerateOverlapEvents(true);
	RootComponent = CollisionComponent;

	SpriteComponent = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Sprite"));
	SpriteComponent->SetupAttachment(RootComponent);
	SpriteComponent->SetRelativeRotation(SeagullSpritePlane()); // Paper2D XZ -> arena XY.
	SpriteComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	SpriteComponent->SetRelativeLocation(FVector(0.f, 0.f, 2.f));

	// Flipbook asset is editor-created (see EDITOR_SETUP.md); null-guarded.
	// Cached: projectiles spawn several times per second while firing.
	if (UPaperFlipbook* Flipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Feather")))
	{
		SpriteComponent->SetFlipbook(Flipbook);
	}

	ProjectileMovement = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("ProjectileMovement"));
	ProjectileMovement->UpdatedComponent = CollisionComponent;
	ProjectileMovement->InitialSpeed = 600.f;
	ProjectileMovement->MaxSpeed = 600.f;
	ProjectileMovement->bRotationFollowsVelocity = false;
	ProjectileMovement->bShouldBounce = false;
	ProjectileMovement->ProjectileGravityScale = 0.f;

	InitialLifeSpan = 3.f;
}

void ASeagullProjectile::InitProjectile(const FVector& Direction, float InDamage, float Speed)
{
	Damage = InDamage;
	if (ProjectileMovement)
	{
		ProjectileMovement->Velocity = Direction.GetSafeNormal() * Speed;
	}
}

void ASeagullProjectile::BeginPlay()
{
	Super::BeginPlay();

	CollisionComponent->OnComponentBeginOverlap.AddDynamic(this, &ASeagullProjectile::OnOverlapBegin);
}

void ASeagullProjectile::OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
	UPrimitiveComponent* OtherComp, int32 OtherBodyIndex,
	bool bFromSweep, const FHitResult& SweepResult)
{
	ASeagullEnemyBase* Enemy = Cast<ASeagullEnemyBase>(OtherActor);
	if (Enemy && !Enemy->IsDead())
	{
		Enemy->TakeDamageAmount(static_cast<int32>(Damage));
		Destroy();
	}
}
