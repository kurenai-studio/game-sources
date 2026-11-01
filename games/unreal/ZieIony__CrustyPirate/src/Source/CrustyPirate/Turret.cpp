// Fill out your copyright notice in the Description page of Project Settings.


#include "Turret.h"
#include "PaperZDAnimInstance.h"
#include "Bullet.h"

ATurret::ATurret() {
	PrimaryActorTick.bCanEverTick = true;

	BulletSpawnLocation = CreateDefaultSubobject<USceneComponent>(TEXT("BulletSpawnLocation"));
	BulletSpawnLocation->SetupAttachment(RootComponent);
}

void ATurret::BeginPlay() {
	Super::BeginPlay();

	auto initialCooldown = attackCooldownInSeconds * (float)rand() / RAND_MAX;
	GetWorldTimerManager().SetTimer(attackCooldownTimer, this, &ATurret::onAttackCooldownTimerTimeout, 1, false, initialCooldown);
}

void ATurret::Tick(float dt) {
	Super::Tick(dt);

	attack();
}

bool ATurret::getIsAlive() {
	return CurrentHitPoints > 0;
}

void ATurret::attack() {
	if (getIsAlive() && canAttack) {
		canAttack = false;

		GetAnimInstance()->JumpToNode(FName("jumpAttack"));

		GetWorldTimerManager().SetTimer(attackCooldownTimer, this, &ATurret::onAttackCooldownTimerTimeout, 1, false, attackCooldownInSeconds);
	}
}

void ATurret::onAttackCooldownTimerTimeout() {
	if (!getIsAlive())
		return;

	canAttack = true;
}

void ATurret::SpawnBullet() {
	GetWorld()->SpawnActor<AParticle>(ParticleClass, BulletSpawnLocation->GetComponentLocation(), GetActorRotation());
	auto spawnParameters = FActorSpawnParameters();
	spawnParameters.Owner = this;
	GetWorld()->SpawnActor<ABullet>(BulletClass, BulletSpawnLocation->GetComponentLocation(), GetActorRotation(), spawnParameters);
}

void ATurret::takeDamage(int damageAmount) {
	if (!getIsAlive())
		return;

	CurrentHitPoints = std::max(0, CurrentHitPoints - damageAmount);

	if (CurrentHitPoints == 0) {
		canAttack = false;

		destroyAndSpawnPieces();
	} else {
		GetAnimInstance()->JumpToNode(FName("jumpHit"));
	}
}

void ATurret::destroyAndSpawnPieces() {
	GetWorld()->SpawnActor<ADestructiblePiece>(DestructiblePiece, GetActorTransform());
	GetWorld()->SpawnActor<ADestructiblePiece>(DestructiblePiece2, GetActorTransform());
	GetWorld()->SpawnActor<ADestructiblePiece>(DestructiblePiece3, GetActorTransform());
	Destroy();
}
