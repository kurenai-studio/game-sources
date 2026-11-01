// Fill out your copyright notice in the Description page of Project Settings.


#include "Enemy.h"
#include <Kismet/GameplayStatics.h>
#include "EnemyHealthBar.h"
#include "PaperZDAnimInstance.h"
#include "PaperZDCharacter.h"
#include <AnimSequences/PaperZDAnimSequence.h>
#include <Components/BoxComponent.h>
#include <Components/SphereComponent.h>
#include <GameFramework/CharacterMovementComponent.h>
#include <Engine/TimerHandle.h>
#include "Particle.h"

AEnemy::AEnemy() {
	PrimaryActorTick.bCanEverTick = true;

	PlayerDetectionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("PlayerDetectionBox"));
	PlayerDetectionBox->SetupAttachment(RootComponent);

	PlayerFollowSphere = CreateDefaultSubobject<USphereComponent>(TEXT("PlayerFollowSphere"));
	PlayerFollowSphere->SetupAttachment(RootComponent);

	UpperLedgeDetectionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("UpperLedgeDetectionBox"));
	UpperLedgeDetectionBox->SetupAttachment(RootComponent);

	LedgeDetectionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("LedgeDetectionBox"));
	LedgeDetectionBox->SetupAttachment(RootComponent);

	WallDetectionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("WallDetectionBox"));
	WallDetectionBox->SetupAttachment(RootComponent);

	AttackDetectionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("AttackDetectionBox"));
	AttackDetectionBox->SetupAttachment(RootComponent);

	AttackCollisionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("AttackCollisionBox"));
	AttackCollisionBox->SetupAttachment(RootComponent);

	DialogueComponent = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Dialogue"));
	DialogueComponent->SetupAttachment(RootComponent);
}

void AEnemy::BeginPlay() {
	Super::BeginPlay();

	PlayerDetectionBox->OnComponentBeginOverlap.AddDynamic(this, &AEnemy::PlayerDetectorOverlapBegin);
	PlayerDetectionBox->OnComponentEndOverlap.AddDynamic(this, &AEnemy::PlayerDetectorOverlapEnd);

	PlayerFollowSphere->OnComponentEndOverlap.AddDynamic(this, &AEnemy::PlayerFollowOverlapEnd);

	UpperLedgeDetectionBox->OnComponentBeginOverlap.AddDynamic(this, &AEnemy::UpperLedgeDetectorOverlapBegin);
	UpperLedgeDetectionBox->OnComponentEndOverlap.AddDynamic(this, &AEnemy::UpperLedgeDetectorOverlapEnd);

	LedgeDetectionBox->OnComponentBeginOverlap.AddDynamic(this, &AEnemy::LedgeDetectorOverlapBegin);
	LedgeDetectionBox->OnComponentEndOverlap.AddDynamic(this, &AEnemy::LedgeDetectorOverlapEnd);

	WallDetectionBox->OnComponentBeginOverlap.AddDynamic(this, &AEnemy::WallDetectorOverlapBegin);
	WallDetectionBox->OnComponentEndOverlap.AddDynamic(this, &AEnemy::WallDetectorOverlapEnd);

	AttackDetectionBox->OnComponentBeginOverlap.AddDynamic(this, &AEnemy::AttackDetectorOverlapBegin);
	AttackDetectionBox->OnComponentEndOverlap.AddDynamic(this, &AEnemy::AttackDetectorOverlapEnd);

	DialogueComponent->SetVisibility(false);
	DialogueComponent->SetLooping(false);
	DialogueComponent->OnFinishedPlaying.AddDynamic(this, &AEnemy::onDialogueFinishedPlaying);

	updateHP(hitPoints);

	OnAttackOverrideEndDelegate.BindUObject(this, &AEnemy::onAttackOverrideAnimEnd);
	AttackCollisionBox->OnComponentBeginOverlap.AddDynamic(this, &AEnemy::AttackBoxOverlapBegin);
	EnableAttackCollisionBox(false);
}

void AEnemy::Tick(float dt) {
	Super::Tick(dt);

	if (getIsAlive() && !isStunned) {
		if (FollowTarget && FollowTarget->getIsAlive()) {

			const float PLAYER_CLOSE_EPSILON = 5;
			float minDist = AttackDetectionBox->GetScaledBoxExtent().X + AttackDetectionBox->GetRelativeLocation().X +
				FollowTarget->GetCapsuleComponent()->GetScaledCapsuleRadius() - PLAYER_CLOSE_EPSILON;
			float distX = FollowTarget->GetActorLocation().X - GetActorLocation().X;

			if (fabs(distX) > minDist && canMove) {
				float dir = distX > 0 ? 1.0f : -1.0f;
				AddMovementInput({ 1,0,0 }, dir, true);
				updateDirection(dir);
				const float LEVEL_HEIGHT_EPSILON = 30;
				if ((isFacingUpperLedge && (FollowTarget->GetActorLocation().Z > GetActorLocation().Z + LEVEL_HEIGHT_EPSILON)) ||
					(isOnLedge && (FollowTarget->GetActorLocation().Z >= GetActorLocation().Z)) ||
					isFacingWall) {
					Jump();
				}
			} else if (inAttackRange) {
				attack();
			}
		} else {
			auto dir = GetActorForwardVector();
			AddMovementInput(dir, 0.5f, true);
		}
	}
}

void AEnemy::PlayerDetectorOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	auto captain = Cast<ACaptain>(otherActor);
	if (captain) {
		GetWorldTimerManager().ClearTimer(lostInterestTimer);
		if (!FollowTarget) {
			FollowTarget = captain;
			playDialogue(DialogueType::QUESTION);
		}
	}
}

void AEnemy::PlayerDetectorOverlapEnd(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex) {
	GetWorldTimerManager().SetTimer(lostInterestTimer, this, &AEnemy::onLostInterestTimerTimeout, 1, false, lostInterestDelaySeconds);
}

void AEnemy::PlayerFollowOverlapEnd(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex) {
	stopFollowing();
}

void AEnemy::UpperLedgeDetectorOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	isFacingUpperLedge = true;
}

void AEnemy::UpperLedgeDetectorOverlapEnd(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex) {
	isFacingUpperLedge = false;
}

void AEnemy::LedgeDetectorOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	isOnLedge = false;
}

void AEnemy::LedgeDetectorOverlapEnd(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex) {
	isOnLedge = true;
	if (!FollowTarget) {
		updateDirection(-GetActorForwardVector().X);
	}
}

void AEnemy::WallDetectorOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	isFacingWall = true;
	if (!FollowTarget) {
		updateDirection(-GetActorForwardVector().X);
	}
}

void AEnemy::WallDetectorOverlapEnd(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex) {
	isFacingWall = false;
}

void AEnemy::AttackDetectorOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	inAttackRange = true;
}

void AEnemy::AttackDetectorOverlapEnd(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex) {
	inAttackRange = false;
}

bool AEnemy::getIsAlive() {
	return hitPoints > 0;
}

void AEnemy::updateDirection(float moveDirection) {
	FRotator currentRotation = GetActorRotation();
	auto dialogueLocation = DialogueComponent->GetRelativeLocation();
	if (moveDirection < 0) {
		SetActorRotation({ currentRotation.Pitch,180,currentRotation.Roll });
		DialogueComponent->SetRelativeLocation(FVector(-fabs(dialogueLocation.X), dialogueLocation.Y, dialogueLocation.Z));
	} else if (moveDirection > 0) {
		SetActorRotation({ currentRotation.Pitch,0,currentRotation.Roll });
		DialogueComponent->SetRelativeLocation(FVector(fabs(dialogueLocation.X), dialogueLocation.Y, dialogueLocation.Z));
	}
}

void AEnemy::updateHP(int newHP) {
	int hpToSet = std::max(0, newHP);
	if (hitPoints != 0 && hpToSet == 0) {
		canMove = false;
		canAttack = false;

		GetAnimInstance()->JumpToNode(FName("jumpDie"));
		EnableAttackCollisionBox(false);
		GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_WorldDynamic, ECR_Ignore);
		GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_Pawn, ECR_Ignore);
		GetSprite()->SetTranslucentSortPriority(1);
	} else if (hitPoints == 0 && hpToSet != 0) {
		canMove = true;
		canAttack = true;

		GetAnimInstance()->JumpToNode(FName("jumpIdle"));
		EnableAttackCollisionBox(true);
		GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_WorldDynamic, ECR_Block);
		GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);
		GetSprite()->SetTranslucentSortPriority(50);
	}

	hitPoints = hpToSet;
	OnHealthChangedEvent.Broadcast(hitPoints);
}

void AEnemy::takeDamage(int damageAmount, float stunDuration, float stunForce, AActor* otherActor) {
	if (!getIsAlive())
		return;

	updateHP(std::max(0, hitPoints - damageAmount));

	if (hitPoints == 0) {
		playDialogue(DialogueType::DEAD, true);
		spawnLoot();
	} else {
		GetAnimInstance()->JumpToNode(FName("jumpTakeHit"));
		playDialogue(DialogueType::EXCLAMATION);
		stun(stunDuration);
		if (ACaptain* captain = Cast<ACaptain>(otherActor)) {
			FollowTarget = captain;
		}
		auto direction = GetActorLocation().X - otherActor->GetActorLocation().X;
		auto stunImpulse = FVector(direction, 0, abs(direction));
		stunImpulse.Normalize();
		stunImpulse = stunImpulse * stunForce;
		GetCharacterMovement()->AddImpulse(stunImpulse);
	}
}

void AEnemy::spawnLoot() {
	if (LootClass) {
		for (int i = 0; i < LootCount; i++) {
			ACollectibleItem::spawn(
				GetWorld(),
				LootClass,
				GetActorLocation(),
				LaunchLootForce
			);
		}
	}
	if (LootClass2) {
		for (int i = 0; i < LootCount2; i++) {
			ACollectibleItem::spawn(
				GetWorld(),
				LootClass2,
				GetActorLocation(),
				LaunchLootForce
			);
		}
	}
}

void AEnemy::onLostInterestTimerTimeout() {
	stopFollowing();
}

void AEnemy::stopFollowing() {
	FollowTarget = nullptr;
	if (isFacingWall || isOnLedge) {
		isFacingWall = false;
		isOnLedge = false;
		updateDirection(-GetActorForwardVector().X);
	}
}

void AEnemy::stun(float durationInSeconds) {
	if (isStunned) {
		GetWorldTimerManager().ClearTimer(stunTimer);
	}
	isStunned = true;
	GetWorldTimerManager().SetTimer(stunTimer, this, &AEnemy::onStunTimerTimeout, 1, false, durationInSeconds);
	GetAnimInstance()->StopAllAnimationOverrides();
	EnableAttackCollisionBox(false);
}

void AEnemy::onStunTimerTimeout() {
	isStunned = false;
}

void AEnemy::attack() {
	if (getIsAlive() && canAttack && !isStunned) {
		canAttack = false;
		canMove = false;

		GetAnimInstance()->PlayAnimationOverride(AttackAnimSequence, FName("DefaultSlot"), 1, 0, OnAttackOverrideEndDelegate);

		GetWorldTimerManager().SetTimer(attackCooldownTimer, this, &AEnemy::onAttackCooldownTimerTimeout, 1, false, attackCooldownInSeconds);
	}
}

void AEnemy::onAttackCooldownTimerTimeout() {
	if (getIsAlive()) {
		canAttack = true;
	}
}

void AEnemy::onAttackOverrideAnimEnd(bool completed) {
	if (getIsAlive()) {
		canMove = true;
	}
}

void AEnemy::AttackBoxOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	auto player = Cast<ACaptain>(otherActor);
	if (player) {
		player->takeDamage(attackDamage, attackStunDuration, attackStunForce, this);
	}
}

void AEnemy::EnableAttackCollisionBox(bool enable) {
	if (enable) {
		AttackCollisionBox->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		AttackCollisionBox->SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
		AttackCollisionBox->SetCollisionResponseToChannel(ECollisionChannel::ECC_Destructible, ECollisionResponse::ECR_Overlap);
	} else {
		AttackCollisionBox->SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AttackCollisionBox->SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
		AttackCollisionBox->SetCollisionResponseToChannel(ECollisionChannel::ECC_Destructible, ECollisionResponse::ECR_Ignore);
	}
}

void AEnemy::playDialogue(DialogueType type, bool force) {
	if ((!force && DialogueComponent->IsVisible()) || (!getIsAlive() && type != DialogueType::DEAD))
		return;

	if (type == DialogueType::DEAD) {
		DialogueComponent->SetFlipbook(DeadFlipbook);
	} else if (type == DialogueType::QUESTION) {
		DialogueComponent->SetFlipbook(QuestionFlipbook);
	} else if (type == DialogueType::EXCLAMATION) {
		DialogueComponent->SetFlipbook(ExclamationFlipbook);
	}
	DialogueComponent->SetVisibility(true);
	DialogueComponent->PlayFromStart();
}

void AEnemy::onDialogueFinishedPlaying() {
	DialogueComponent->SetVisibility(false);
}

void AEnemy::SpawnRunDust() {
	float maxSpeed = GetCharacterMovement()->GetMaxSpeed();
	float currentSpeed = fabs(GetVelocity().X);
	if (currentSpeed > maxSpeed / 2) {
		GetWorld()->SpawnActor<AParticle>(DustClass, GetActorTransform());
	}
}

FEnemySaveData AEnemy::getSaveData() {
	return {
		.health = hitPoints,
		.transform = GetActorTransform(),
		.type = GetClass()
	};
}

void AEnemy::setSaveData(FEnemySaveData& saveData) {
	SetActorTransform(saveData.transform);
	updateHP(saveData.health);
}

AEnemy* AEnemy::spawn(UWorld* world, FEnemySaveData& saveData) {
	FActorSpawnParameters enemySpawnParameters = {};
	enemySpawnParameters.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AEnemy* enemy = (AEnemy*)world->SpawnActor(saveData.type, &saveData.transform, enemySpawnParameters);
	enemy->setSaveData(saveData);
	return enemy;
}
