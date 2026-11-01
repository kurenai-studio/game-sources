#include "Pickups/SeagullPickup.h"
#include "Animation/SeagullSpritePlane.h"
#include "Player/SeagullPlayerPawn.h"
#include "Components/SphereComponent.h"
#include "PaperFlipbookComponent.h"

ASeagullPickup::ASeagullPickup()
{
	PrimaryActorTick.bCanEverTick = true;
	Tags.Add(TEXT("Pickup"));

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

	InitialLifeSpan = 30.f;
}

void ASeagullPickup::BeginPlay()
{
	Super::BeginPlay();
	CollisionComponent->OnComponentBeginOverlap.AddDynamic(this, &ASeagullPickup::OnOverlapBegin);
}

void ASeagullPickup::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	if (SpriteComponent) SpriteComponent->SetRelativeLocation(FVector(0.f, 0.f, 3.f + FMath::Sin(GetWorld()->GetTimeSeconds() * 4.f + GetUniqueID()) * 1.5f));
}

void ASeagullPickup::OnPickedUp(ASeagullPlayerPawn* Player)
{
	Destroy();
}

void ASeagullPickup::OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
	UPrimitiveComponent* OtherComp, int32 OtherBodyIndex,
	bool bFromSweep, const FHitResult& SweepResult)
{
	ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(OtherActor);
	if (Player)
	{
		OnPickedUp(Player);
	}
}
