// Fill out your copyright notice in the Description page of Project Settings.


#include "Chest.h"
#include <Components/BoxComponent.h>
#include "PaperFlipbookComponent.h"
#include "PaperFlipbook.h"
#include "CollectibleItem.h"
#include "Captain.h"
#include <Sound/SoundBase.h>
#include <Kismet/GameplayStatics.h>

// Sets default values
AChest::AChest()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("BoxComponent"));
	SetRootComponent(BoxComponent);

	Sprite = CreateOptionalDefaultSubobject<UPaperFlipbookComponent>(TEXT("Sprite"));
	Sprite->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void AChest::BeginPlay()
{
	Super::BeginPlay();
	BoxComponent->OnComponentBeginOverlap.AddDynamic(this, &AChest::OverlapBegin);
}

// Called every frame
void AChest::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void AChest::unlock() {
	if (!locked)
		return;
	locked = false;

	Sprite->SetFlipbook(UnlockedFlipbook);
	Sprite->SetLooping(false);
	UGameplayStatics::PlaySound2D(GetWorld(), UnlockSound);
	
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

	OnChestOpenedEvent.Broadcast();
}

void AChest::OverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	if (auto captain = Cast<ACaptain>(otherActor)) {
		if (captain->tryUnlock()) {
			unlock();
		}
	}
}

