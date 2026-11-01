// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "EnemyManager.h"


// Sets default values for this component's properties
UEnemyManager::UEnemyManager()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	static ConstructorHelpers::FObjectFinder<UClass> EnemyProjectileClassFinder(TEXT("Blueprint'/Game/Blueprints/AEnemyProjectile_BP.AEnemyProjectile_BP_C'"));
	Projectile = EnemyProjectileClassFinder.Object;
}


// Called when the game starts
void UEnemyManager::BeginPlay()
{
	Super::BeginPlay();

	// ...
	
}


// Called every frame
void UEnemyManager::TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction )
{
	Super::TickComponent( DeltaTime, TickType, ThisTickFunction );
	if (Health <= 0)
	{
		DestroyEnemy();
	}
}

void UEnemyManager::Shoot() {
	UE_LOG(LogTemp, Warning, TEXT("ENEMY SHOOT"));
	this->SpawnProjectile();

}

void UEnemyManager::SpawnProjectile() {

	FVector ProjectilePosition = GetOwner()->GetActorLocation();
	FRotator ProjectileRotation = GetOwner()->GetActorRotation();
	FActorSpawnParameters SpawnInfo;
	if (Projectile != NULL)
		AEnemyProjecile* projectile = GetWorld()->SpawnActor<AEnemyProjecile>(Projectile, ProjectilePosition, ProjectileRotation, SpawnInfo);
	else
		UE_LOG(LogTemp, Warning, TEXT("ENEMY Projectile not found"));

}

void UEnemyManager::OnHit()
{
	Health--;
}

void UEnemyManager::DestroyEnemy()
{
	GetOwner()->Destroy();
}

