// Fill out your copyright notice in the Description page of Project Settings.


#include "Particle.h"
#include <PaperFlipbookComponent.h>

// Sets default values
AParticle::AParticle() {
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	Sprite = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Sprite"));
	Sprite->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void AParticle::BeginPlay() {
	Super::BeginPlay();

	Sprite->SetLooping(false);
	Sprite->OnFinishedPlaying.AddDynamic(this, &AParticle::OnSpriteAnimationFinished);
}

// Called every frame
void AParticle::Tick(float DeltaTime) {
	Super::Tick(DeltaTime);
}

void AParticle::OnSpriteAnimationFinished() {
	Destroy();
}
