// Fill out your copyright notice in the Description page of Project Settings.


#include "PalmTreePlatform.h"
#include <Components/BoxComponent.h>
#include "PaperFlipbookComponent.h"
#include "PaperTileMapComponent.h"

// Sets default values
APalmTreePlatform::APalmTreePlatform()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("BoxComponent"));
	SetRootComponent(BoxComponent);

	LeavesFlipbook = CreateOptionalDefaultSubobject<UPaperFlipbookComponent>(TEXT("Leaves"));
	LeavesFlipbook->SetupAttachment(RootComponent);

	StemTileMap = CreateOptionalDefaultSubobject<UPaperTileMapComponent>(TEXT("Stem"));
	StemTileMap->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void APalmTreePlatform::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void APalmTreePlatform::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

