// Fill out your copyright notice in the Description page of Project Settings.

#include "Sound/SoundBase.h"
#include "Kismet/GameplayStatics.h"
#include "Coin.h"
#include "MainGameMode.h"


AMainGameMode::AMainGameMode() {

	PrimaryActorTick.bCanEverTick = true;


}


void AMainGameMode::BeginPlay() {

Super::BeginPlay();  

 
///This is cool

 UGameplayStatics::PlaySound2D(this, BackgroundSound);
}


void AMainGameMode::Tick(float DeltaTime) {

	Super::Tick(DeltaTime); 


	
}


