// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "PlayerProjectile.h"


// Sets default values
APlayerProjectile::APlayerProjectile()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void APlayerProjectile::BeginPlay()
{
	Super::BeginPlay();
	APlayerCameraManager* camera = Cast<APlayerCameraManager>(UGameplayStatics::GetPlayerCameraManager(GetWorld(), 0));

	
}

// Called every frame
void APlayerProjectile::Tick( float DeltaTime )
{
	Super::Tick( DeltaTime );

}

void APlayerProjectile::OnCollision(ECollisionChannel other, AActor* actor) {
	if (other == ECollisionChannel::ECC_GameTraceChannel1) {
		Destroy();
	}
	else if (other == ECollisionChannel::ECC_GameTraceChannel3) {
		const FString command = FString::Printf(TEXT("DecreaseHealth"));
		FOutputDeviceDebug debug;
		actor->CallFunctionByNameWithArguments(*command, debug, this, true);
	}
}