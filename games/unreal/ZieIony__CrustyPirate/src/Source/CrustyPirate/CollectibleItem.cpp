// Fill out your copyright notice in the Description page of Project Settings.


#include "CollectibleItem.h"
#include "Captain.h"
#include <Kismet/GameplayStatics.h>

// Sets default values
ACollectibleItem::ACollectibleItem()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	CapsuleComp = CreateDefaultSubobject<UCapsuleComponent>(TEXT("CapsuleComp"));
	SetRootComponent(CapsuleComp);

	ItemFlipbook = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("ItemFlipbook"));
	ItemFlipbook->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void ACollectibleItem::BeginPlay()
{
	Super::BeginPlay();
	
	CapsuleComp->OnComponentBeginOverlap.AddDynamic(this, &ACollectibleItem::OverlapBegin);
	auto location = GetActorLocation();
	SetActorLocation({ round(location.X / 64) * 64, location.Y, round(location.Z / 64) * 64 });
}

// Called every frame
void ACollectibleItem::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void ACollectibleItem::OverlapBegin(
	UPrimitiveComponent* overlappedComponent,
	AActor* otherActor,
	UPrimitiveComponent* otherComponent,
	int32 otherBodyIndex,
	bool fromSweep,
	const FHitResult& sweepResults
) {
	ACaptain* player = Cast<ACaptain>(otherActor);
	if (player && player->tryCollectItem(*this)) {
		if(CollectItemSound)
			UGameplayStatics::PlaySound2D(GetWorld(), CollectItemSound);
		Destroy();
	}
}

void ACollectibleItem::spawn(UWorld* world, TSubclassOf<ACollectibleItem> subclass, FVector location, float launchForce) {
	auto* collectibleItem = world->SpawnActor<ACollectibleItem>(
		subclass,
		location,
		FRotator::ZeroRotator
	);
	if (collectibleItem) {
		auto force = FVector((float)rand() / RAND_MAX * 2 - 1, 0, 1);
		force.Normalize();
		collectibleItem->CapsuleComp->AddImpulse(force * launchForce);
	} else {
		UE_LOG(LogTemp, Warning, TEXT("Collectible item spawned null"));
	}
}

FCollectibleSaveData ACollectibleItem::getSaveData() {
	FCollectibleSaveData saveData = {
		.transform = GetActorTransform(),
		.type = GetClass()
	};
	return saveData;
}

ACollectibleItem* ACollectibleItem::spawn(UWorld* world, FCollectibleSaveData& saveData) {
	FActorSpawnParameters collectibleSpawnParameters = {};
	collectibleSpawnParameters.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	ACollectibleItem* collectible = (ACollectibleItem*)world->SpawnActor(saveData.type, &saveData.transform, collectibleSpawnParameters);
	collectible->SetActorTransform(saveData.transform);
	return collectible;
}
