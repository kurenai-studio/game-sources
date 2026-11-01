// Fill out your copyright notice in the Description page of Project Settings.


#include "DestructiblePiece.h"
#include "PaperSpriteComponent.h"
#include <Components/BoxComponent.h>

// Sets default values
ADestructiblePiece::ADestructiblePiece() {
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("BoxComponent"));
	SetRootComponent(BoxComponent);

	Sprite = CreateOptionalDefaultSubobject<UPaperSpriteComponent>(TEXT("Sprite"));
	Sprite->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void ADestructiblePiece::BeginPlay() {
	Super::BeginPlay();

	auto launchImpulse = LaunchOffset;
	launchImpulse.Normalize();
	BoxComponent->AddImpulse(launchImpulse * LaunchForce);

	if (DestroyDelay != 0) {
		GetWorldTimerManager().SetTimer(
			destroyTimer,
			this,
			&ADestructiblePiece::onDestroyTimerTimeout,
			1,
			false,
			DestroyDelay
		);
	}
}

// Called every frame
void ADestructiblePiece::Tick(float DeltaTime) {
	Super::Tick(DeltaTime);

}

void ADestructiblePiece::onDestroyTimerTimeout() {
	Destroy();
}

