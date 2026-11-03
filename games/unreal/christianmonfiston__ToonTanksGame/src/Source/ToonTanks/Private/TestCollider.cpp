// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/BoxComponent.h"
#include "Components/PrimitiveComponent.h"
#include "Components/StaticMeshComponent.h"
#include "DrawDebugHelpers.h"
#include "TestCollider.h"

// Sets default values
ATestCollider::ATestCollider()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	BoxCollider = CreateDefaultSubobject<UBoxComponent>(TEXT("BOX COMPONENT")); 

	RootComponent = BoxCollider; 

	FVector Extent = FVector(50.f, 50.f, 50.f); 

	BoxCollider->InitBoxExtent(Extent); 

	BoxMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BOX MESH"));

	BoxMesh->SetupAttachment(BoxCollider); 

	BoxCollider->OnComponentBeginOverlap.AddDynamic(this, &ATestCollider::OnComponentBeginOverlap); 



}

// Called when the game starts or when spawned
void ATestCollider::BeginPlay()
{
	Super::BeginPlay();

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 10.f, FColor::Red, TEXT("Box Collider is Working")); 
	}
}

// Called every frame
void ATestCollider::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void ATestCollider::OnComponentBeginOverlap(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult){

	if (GEngine) {
		GEngine->AddOnScreenDebugMessage(-1, 10.f, FColor::Red, TEXT("Collision is Working"));
	}
}


