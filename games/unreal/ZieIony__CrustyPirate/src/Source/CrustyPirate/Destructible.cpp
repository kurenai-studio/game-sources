// Fill out your copyright notice in the Description page of Project Settings.


#include "Destructible.h"
#include "PaperZDAnimationComponent.h"
#include <PaperCharacter.h>
#include "PaperFlipbookComponent.h"
#include "Captain.h"
#include "CollectibleItem.h"

// Sets default values
ADestructible::ADestructible() {
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("BoxComponent"));
	SetRootComponent(BoxComponent);

	Sprite = CreateOptionalDefaultSubobject<UPaperFlipbookComponent>(TEXT("Sprite"));
	Sprite->SetupAttachment(RootComponent);

	AnimationComponent = CreateDefaultSubobject<UPaperZDAnimationComponent>(TEXT("Animation"));
	AnimationComponent->InitRenderComponent(Sprite);

	DestructiblePieceLocation = CreateDefaultSubobject<USceneComponent>(TEXT("DestructiblePieceLocation"));
	DestructiblePieceLocation->SetupAttachment(RootComponent);

	DestructiblePieceLocation2 = CreateDefaultSubobject<USceneComponent>(TEXT("DestructiblePieceLocation2"));
	DestructiblePieceLocation2->SetupAttachment(RootComponent);

	DestructiblePieceLocation3 = CreateDefaultSubobject<USceneComponent>(TEXT("DestructiblePieceLocation3"));
	DestructiblePieceLocation3->SetupAttachment(RootComponent);

	DestructiblePieceLocation4 = CreateDefaultSubobject<USceneComponent>(TEXT("DestructiblePieceLocation4"));
	DestructiblePieceLocation4->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void ADestructible::BeginPlay() {
	Super::BeginPlay();
}

// Called every frame
void ADestructible::Tick(float DeltaTime) {
	Super::Tick(DeltaTime);
}

void ADestructible::takeDamage(int damageAmount) {
	if (CurrentHitPoints <= 0)
		return;

	CurrentHitPoints = std::max(0, CurrentHitPoints - damageAmount);

	if (CurrentHitPoints == 0) {
		destroyAndSpawnContents();
	} else {
		AnimationComponent->GetAnimInstance()->JumpToNode(FName("jumpHit"));
	}
}

void ADestructible::destroyAndSpawnContents() {
	if (ContentsClass) {
		for (int i = 0; i < ContentsCount; i++) {
			ACollectibleItem::spawn(
				GetWorld(),
				ContentsClass,
				GetActorLocation(),
				LaunchContentsForce
			);
		}
	}
	if (ContentsClass2) {
		for (int i = 0; i < ContentsCount2; i++) {
			ACollectibleItem::spawn(
				GetWorld(),
				ContentsClass2,
				GetActorLocation(),
				LaunchContentsForce
			);
		}
	}
	GetWorld()->SpawnActor<ADestructiblePiece>(
		DestructiblePiece,
		DestructiblePieceLocation->GetComponentLocation(),
		FRotator::ZeroRotator
	);
	GetWorld()->SpawnActor<ADestructiblePiece>(
		DestructiblePiece2,
		DestructiblePieceLocation2->GetComponentLocation(),
		FRotator::ZeroRotator
	);
	GetWorld()->SpawnActor<ADestructiblePiece>(
		DestructiblePiece3,
		DestructiblePieceLocation3->GetComponentLocation(),
		FRotator::ZeroRotator
	);
	GetWorld()->SpawnActor<ADestructiblePiece>(
		DestructiblePiece4,
		DestructiblePieceLocation4->GetComponentLocation(),
		FRotator::ZeroRotator
	);
	Destroy();
}

