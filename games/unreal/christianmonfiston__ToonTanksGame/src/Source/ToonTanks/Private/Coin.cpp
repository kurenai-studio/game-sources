// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Components/PrimitiveComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Particles/ParticleSystem.h"
#include "Sound/SoundBase.h"
#include "Math/UnrealMathUtility.h"
#include "Camera/CameraComponent.h"
#include "Math/RandomStream.h"
#include "ToonTanks/Projectile.h"
#include "Kismet/GameplayStatics.h"
#include "Camera/CameraComponent.h"
#include "Components/SphereComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "DrawDebugHelpers.h"
#include "Coin.h"

// Sets default values
ACoin::ACoin()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;



	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("BOX COMPONENT")); 
	RootComponent = BoxComponent; 

	CoinMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh Component")); 

	CoinMesh->SetupAttachment(BoxComponent); 

	FVector BoxSize = FVector(60.f, 60.f, 60.f); 
	BoxComponent->SetBoxExtent(BoxSize); 

	


}

// Called when the game starts or when spawned
void ACoin::BeginPlay()
{
	Super::BeginPlay();

	//BoxComponent->OnComponentHit.AddDynamic(this, &ACoin::OnHit); 


	BoxComponent->OnComponentBeginOverlap.AddDynamic(this, &ACoin::OnBoxBeginOverlap);

	Min = 10;
	Max = 50;
	RandomInt = FMath::RandRange(Min, Max);

	//Get Projectile
	
}

// Called every frame
void ACoin::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	RotateCoin(); 


}

void ACoin::DebugMessage() {

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 15.f, FColor::Emerald, TEXT("Rotation is working")); 
	}
}

void ACoin::RotateCoin() {

	

	CoinRotation = FRotator::ZeroRotator;

	RotationRate = 10.f;

	float RotationSpeed = 10.f;


	CoinRotation.Yaw = TimeDelta * RotationRate * RotationSpeed;

	AddActorLocalRotation(CoinRotation, true);

}

void ACoin::OnHit(UPrimitiveComponent* HitComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, FVector NormalImpulse, const FHitResult& Hit) {

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 10.f, FColor::Magenta, TEXT("Collision is working")); 
	}
	Destroy();
}


void ACoin::OnBoxBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult) {
	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 10.f, FColor::Magenta, TEXT("Coin collision is working"));
	}

	FVector CoinLocation = GetActorLocation(); 
	UGameplayStatics::PlaySoundAtLocation(this, CoinSound, CoinLocation);

	Destroy(); 
	
}


void ACoin::SpawnCoin() {

	

	int32 NumberOfCoins = 10;
	FVector Location =FVector::ZeroVector;
	FRotator Rotation = FRotator::ZeroRotator;
	;


	for (int32 i = 0; i < NumberOfCoins; i++) {
		GetWorld()->SpawnActor<ACoin>(CoinClass, Location, Rotation);
	}



}





