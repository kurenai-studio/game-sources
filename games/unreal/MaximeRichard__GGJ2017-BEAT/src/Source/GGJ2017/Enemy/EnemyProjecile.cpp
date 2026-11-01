// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "EnemyProjecile.h"


// Sets default values
AEnemyProjecile::AEnemyProjecile()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;


}

// Called when the game starts or when spawned
void AEnemyProjecile::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void AEnemyProjecile::Tick( float DeltaTime )
{
	Super::Tick( DeltaTime );

}

void AEnemyProjecile::OnCollision(ECollisionChannel other, AActor* actor) {
	if (other == ECollisionChannel::ECC_GameTraceChannel2) {
		APlayerPawn* PlayerPawn = Cast<APlayerPawn>(actor);
		if (PlayerPawn) {
			PlayerPawn->OnLoseLife();
		}
		Destroy();
	}
	else if (other == ECollisionChannel::ECC_GameTraceChannel1) {
		Destroy();
	}
}

