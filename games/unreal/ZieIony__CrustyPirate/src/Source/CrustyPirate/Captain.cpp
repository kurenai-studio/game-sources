#include "Captain.h"
#include "Enemy.h"
#include "GameFramework/CharacterMovementComponent.h"
#include <EnhancedInputComponent.h>
#include <EnhancedInputSubsystems.h>
#include <Kismet/GameplayStatics.h>
#include <Kismet/KismetSystemLibrary.h>
#include "Destructible.h"
#include "Chest.h"
#include "Turret.h"
#include "LevelExit.h"

ACaptain::ACaptain() {
	PrimaryActorTick.bCanEverTick = true;

	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArm"));
	SpringArm->SetupAttachment(RootComponent);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm, USpringArmComponent::SocketName);

	AttackCollisionBox = CreateDefaultSubobject<UBoxComponent>(TEXT("AttackCollisionBox"));
	AttackCollisionBox->SetupAttachment(RootComponent);

	DialogueComponent = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Dialogue"));
	DialogueComponent->SetupAttachment(RootComponent);

	SwordSpawnLocation = CreateDefaultSubobject<USceneComponent>(TEXT("SwordSpawnLocation"));
	SwordSpawnLocation->SetupAttachment(RootComponent);
}

void ACaptain::BeginPlay() {
	Super::BeginPlay();

	APlayerController* playerController = Cast<APlayerController>(Controller);
	if (playerController) {
		auto* subsystem = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(
			playerController->GetLocalPlayer()
		);
		if (subsystem) {
			subsystem->AddMappingContext(InputMappingContext, 0);
		}
	}

	OnAttackOverrideEndDelegate.BindUObject(this, &ACaptain::onAttackOverrideAnimEnd);
	AttackCollisionBox->OnComponentBeginOverlap.AddDynamic(this, &ACaptain::AttackBoxOverlapBegin);
	EnableAttackCollisionBox(false);

	DialogueComponent->SetVisibility(false);
	DialogueComponent->SetLooping(false);
	DialogueComponent->OnFinishedPlaying.AddDynamic(this, &ACaptain::onDialogueFinishedPlaying);

	MyGameInstance = Cast<UMyGameInstance>(GetGameInstance());
	if (MyGameInstance) {
		if (MyGameInstance->IsDoubleJumpUnlocked) {
			unlockDoubleJump();
		}
	}

	GetWorldTimerManager().SetTimer(idleTimer, this, &ACaptain::onIdleTimerTimeout, 1, false, IdleDelay);
}

void ACaptain::Tick(float dt) {
	Super::Tick(dt);
}

void ACaptain::SetupPlayerInputComponent(UInputComponent* playerInputComponent) {
	Super::SetupPlayerInputComponent(playerInputComponent);

	auto* enhancedInputComponent = Cast<UEnhancedInputComponent>(playerInputComponent);
	if (enhancedInputComponent) {
		enhancedInputComponent->BindAction(MoveAction, ETriggerEvent::Triggered, this, &ACaptain::move);

		enhancedInputComponent->BindAction(AttackAction, ETriggerEvent::Started, this, &ACaptain::attack);

		enhancedInputComponent->BindAction(JumpAction, ETriggerEvent::Started, this, &ACaptain::jumpStarted);
		enhancedInputComponent->BindAction(JumpAction, ETriggerEvent::Completed, this, &ACaptain::jumpEnded);
		enhancedInputComponent->BindAction(JumpAction, ETriggerEvent::Canceled, this, &ACaptain::jumpEnded);

		enhancedInputComponent->BindAction(QuitAction, ETriggerEvent::Started, this, &ACaptain::quitGame);
		enhancedInputComponent->BindAction(SaveGameAction, ETriggerEvent::Started, this, &ACaptain::saveGame);
		enhancedInputComponent->BindAction(LoadGameAction, ETriggerEvent::Started, this, &ACaptain::loadGame);
	} else {
		throw std::exception("enhancedInputComponent is null");
	}
}

bool ACaptain::getIsAlive() {
	return MyGameInstance->PlayerHP > 0;
}

void ACaptain::move(const FInputActionValue& value) {
	float moveActionValue = value.Get<float>();
	if (getIsAlive() && canMove && !isStunned && fabs(moveActionValue) >= 0.1) {
		FVector dir = { 1,0,0 };
		AddMovementInput(dir, moveActionValue);
		updateDirection(moveActionValue);
		GetWorldTimerManager().ClearTimer(idleTimer);
		GetWorldTimerManager().SetTimer(idleTimer, this, &ACaptain::onIdleTimerTimeout, 1, false, IdleDelay);
	}
}

void ACaptain::updateDirection(float moveDirection) {
	FRotator currentRotation = Controller->GetControlRotation();
	auto dialogueLocation = DialogueComponent->GetRelativeLocation();
	if (moveDirection < -0.1) {
		Controller->SetControlRotation({ currentRotation.Pitch,180,currentRotation.Roll });
		DialogueComponent->SetRelativeLocation(FVector(-fabs(dialogueLocation.X), dialogueLocation.Y, dialogueLocation.Z));
	} else if (moveDirection > 0.1) {
		Controller->SetControlRotation({ currentRotation.Pitch,0,currentRotation.Roll });
		DialogueComponent->SetRelativeLocation(FVector(fabs(dialogueLocation.X), dialogueLocation.Y, dialogueLocation.Z));
	}
}

void ACaptain::jumpStarted(const FInputActionValue& value) {
	if (getIsAlive() && canMove && !isStunned)
		Jump();
}

void ACaptain::jumpEnded(const FInputActionValue& value) {
	StopJumping();
	GetWorldTimerManager().ClearTimer(idleTimer);
	GetWorldTimerManager().SetTimer(idleTimer, this, &ACaptain::onIdleTimerTimeout, 1, false, IdleDelay);
}

void ACaptain::attack(const FInputActionValue& value) {
	if (getIsAlive() && canAttack && !isStunned) {
		canAttack = false;
		canMove = false;

		GetWorldTimerManager().ClearTimer(idleTimer);
		GetWorldTimerManager().SetTimer(idleTimer, this, &ACaptain::onIdleTimerTimeout, 1, false, IdleDelay);

		if (MyGameInstance->SwordsOwned > 0) {
			attackRanged();
		} else {
			attackMelee();
		}
	}
}

void ACaptain::attackMelee() {
	if (GetVelocity().Z != 0) {
		auto animation = ((float)rand() / RAND_MAX) > 0.5f ? AirAttackAnimSequence : AirAttack2AnimSequence;
		GetAnimInstance()->PlayAnimationOverride(animation, FName("attackSlot"), 1, 0, OnAttackOverrideEndDelegate);
	} else {
		auto animation = [&] {
			float index = (float)rand() / RAND_MAX;
			if (index < 0.333f) {
				return AttackAnimSequence;
			} else if (index < 0.667f) {
				return Attack2AnimSequence;
			} else {
				return Attack3AnimSequence;
			}
		}();
		GetAnimInstance()->PlayAnimationOverride(animation, FName("attackSlot"), 1, 0, OnAttackOverrideEndDelegate);
	}
}

void ACaptain::attackRanged() {
	GetAnimInstance()->PlayAnimationOverride(ThrowAnimSequence, FName("attackSlot"), 1, 0, OnAttackOverrideEndDelegate);
}

void ACaptain::ThrowSword() {
	MyGameInstance->useSword();
	auto spawnParameters = FActorSpawnParameters();
	spawnParameters.Owner = this;
	GetWorld()->SpawnActor<ABullet>(SwordClass, SwordSpawnLocation->GetComponentLocation(), GetActorRotation(), spawnParameters);
}

void ACaptain::onAttackOverrideAnimEnd(bool completed) {
	if (isActive && getIsAlive()) {
		canAttack = true;
		canMove = true;
	}
}

void ACaptain::AttackBoxOverlapBegin(UPrimitiveComponent* overlappedComponent, AActor* otherActor, UPrimitiveComponent* otherComponent, int32 otherBodyIndex, bool fromSweep, const FHitResult& sweepResults) {
	if (auto enemy = Cast<AEnemy>(otherActor)) {
		enemy->takeDamage(AttackDamage, AttackStunDuration, AttackStunForce, this);
	} else if (auto turret = Cast<ATurret>(otherActor)) {
		turret->takeDamage(AttackDamage);
	} else if (auto destructible = Cast<ADestructible>(otherActor)) {
		destructible->takeDamage(AttackDamage);
	} else if (auto chest = Cast<AChest>(otherActor)) {
		chest->unlock();
	}
}

void ACaptain::EnableAttackCollisionBox(bool enable) {
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

void ACaptain::takeDamage(int damageAmount, float stunDuration, float stunForce, AActor* otherActor) {
	if (!getIsAlive() || !isActive)
		return;

	EnableAttackCollisionBox(false);
	updateHP(std::max(0, MyGameInstance->PlayerHP - damageAmount));

	if (MyGameInstance->PlayerHP == 0) {
		float restartDelay = 3;
		GetWorldTimerManager().SetTimer(restartTimer, this, &ACaptain::onRestartTimerTimeout, 1, false, restartDelay);
		GetWorldTimerManager().ClearTimer(idleTimer);
		playDialogue(DialogueType::DEAD, true);
	} else {
		stun(stunDuration);
		playDialogue(DialogueType::EXCLAMATION);
		GetAnimInstance()->JumpToNode(FName("jumpTakeHit"));

		auto direction = GetActorLocation().X - otherActor->GetActorLocation().X;
		auto stunImpulse = FVector(direction, 0, abs(direction));
		stunImpulse.Normalize();
		stunImpulse = stunImpulse * stunForce;
		GetCharacterMovement()->AddImpulse(stunImpulse);
	}
}

void ACaptain::updateHP(int newHP) {
	if (MyGameInstance->PlayerHP != 0 && newHP == 0) {
		canMove = false;
		canAttack = false;

		GetAnimInstance()->JumpToNode(FName("jumpDie"));
	} else if (MyGameInstance->PlayerHP == 0 && newHP != 0) {
		canMove = true;
		canAttack = true;

		GetAnimInstance()->JumpToNode(FName("jumpIdle"));
	}

	MyGameInstance->setPlayerHP(newHP);
}

void ACaptain::stun(float durationInSeconds) {
	if (isStunned) {
		GetWorldTimerManager().ClearTimer(stunTimer);
	}
	isStunned = true;
	GetWorldTimerManager().SetTimer(stunTimer, this, &ACaptain::onStunTimerTimeout, 1, false, durationInSeconds);
	GetAnimInstance()->StopAllAnimationOverrides();
	EnableAttackCollisionBox(false);
}

void ACaptain::onStunTimerTimeout() {
	isStunned = false;
}

void ACaptain::onRestartTimerTimeout() {
	MyGameInstance->restartGame();
}

bool ACaptain::tryCollectItem(ACollectibleItem& item) {
	if (!getIsAlive())
		return false;

	switch (item.Type) {
	case CollectibleType::Potion:
		if (MyGameInstance->PlayerHP == MaxHitPoints)
			return false;
		updateHP(std::min(MyGameInstance->PlayerHP + item.Value, MaxHitPoints));
		break;
	case CollectibleType::Coin:
		MyGameInstance->collectCoins(item.Value);
		break;
	case CollectibleType::Diamond:
		MyGameInstance->collectDiamonds(item.Value);
		break;
	case CollectibleType::DoubleJumpUpgrade:
		unlockDoubleJump();
		break;
	case CollectibleType::Key:
		MyGameInstance->collectKey();
		break;
	case CollectibleType::Map:
	{
		MyGameInstance->collectMap();
		TArray<AActor*> exits;
		UGameplayStatics::GetAllActorsOfClass(GetWorld(), ALevelExit::StaticClass(), exits);
		Cast<ALevelExit>(exits[0])->activate();
	}
	break;
	case CollectibleType::Sword:
		MyGameInstance->collectSwords(item.Value);
		break;
	}
	return true;
}

bool ACaptain::tryUnlock() {
	if (MyGameInstance->KeysOwned > 0) {
		MyGameInstance->useKey();
		return true;
	}
	return false;
}

void ACaptain::unlockDoubleJump() {
	JumpMaxCount = 2;
	MyGameInstance->IsDoubleJumpUnlocked = true;
}

void ACaptain::deactivate() {
	if (isActive) {
		isActive = false;
		canAttack = false;
		canMove = false;

		GetCharacterMovement()->StopMovementImmediately();
	}
}

void ACaptain::quitGame() {
	UKismetSystemLibrary::QuitGame(GetWorld(), UGameplayStatics::GetPlayerController(GetWorld(), 0), EQuitPreference::Quit, false);
}

void ACaptain::saveGame() {
	MyGameInstance->saveGame(false);
}

void ACaptain::loadGame() {
	MyGameInstance->loadGame();
}

void ACaptain::playDialogue(DialogueType type, bool force) {
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

void ACaptain::onDialogueFinishedPlaying() {
	DialogueComponent->SetVisibility(false);
}

void ACaptain::onIdleTimerTimeout() {
	playDialogue(DialogueType::QUESTION);
}

FCaptainSaveData ACaptain::getSaveData() {
	return {
		.transform = GetActorTransform()
	};
}

void ACaptain::setSaveData(FCaptainSaveData& saveData) {
	SetActorTransform(saveData.transform);
}
