// Fill out your copyright notice in the Description page of Project Settings.


#include "LevelExit.h"
#include "Captain.h"
#include "MyGameInstance.h"
#include <Kismet/GameplayStatics.h>

// Sets default values
ALevelExit::ALevelExit() {
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	BoxComp = CreateDefaultSubobject<UBoxComponent>(TEXT("BoxComp"));
	SetRootComponent(BoxComp);

	Flipbook = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Flipbook"));
	Flipbook->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void ALevelExit::BeginPlay() {
	Super::BeginPlay();

	BoxComp->OnComponentBeginOverlap.AddDynamic(this, &ALevelExit::OverlapBegin);
}

// Called every frame
void ALevelExit::Tick(float DeltaTime) {
	Super::Tick(DeltaTime);

}

void ALevelExit::OverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	ACaptain* player = Cast<ACaptain>(otherActor);
	if (player && player->getIsAlive() && player->isActive && isActive) {
		player->deactivate();
		UGameplayStatics::PlaySound2D(GetWorld(), PlayerEnterSound);
		GetWorldTimerManager().SetTimer(delayTimer, this, &ALevelExit::onDelayTimerTimeout, 1.0f, false, delayTimeSec);
	}
}

void ALevelExit::onDelayTimerTimeout() {
	auto gameInstance = Cast<UMyGameInstance>(GetGameInstance());
	if (gameInstance) {
		gameInstance->finishLevel();
	}

}

void ALevelExit::activate() {
	isActive = true;
	Flipbook->SetFlipbook(ActiveFlipbook);
}

