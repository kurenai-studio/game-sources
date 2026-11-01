// Copyright Epic Games, Inc. All Rights Reserved.
// Copyright (c) 2022 Noah Wood

#include "Aghanim_RPGCharacter.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"

//////////////////////////////////////////////////////////////////////////
// AAghanim_RPGCharacter


AAghanim_RPGCharacter::AAghanim_RPGCharacter()
{
	// Set size for collision capsule
	GetCapsuleComponent()->InitCapsuleSize(42.f, 96.0f);

	// set our turn rate for input
	TurnRateGamepad = 50.f;

	// Don't rotate when the controller rotates. Let that just affect the camera.
	bUseControllerRotationPitch = false;
	bUseControllerRotationYaw = false;
	bUseControllerRotationRoll = false;

	// Configure character movement
	GetCharacterMovement()->bOrientRotationToMovement = true; // Character moves in the direction of input...	
	GetCharacterMovement()->RotationRate = FRotator(0.0f, 500.0f, 0.0f); // ...at this rotation rate

	// Note: For faster iteration times these variables, and many more, can be tweaked in the Character Blueprint
	// instead of recompiling to adjust them
	GetCharacterMovement()->JumpZVelocity = 700.f;
	GetCharacterMovement()->AirControl = 0.35f;
	GetCharacterMovement()->MaxWalkSpeed = 500.f;
	GetCharacterMovement()->MinAnalogWalkSpeed = 20.f;
	GetCharacterMovement()->BrakingDecelerationWalking = 2000.f;

	// Create a camera boom (pulls in towards the player if there is a collision)
	CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
	CameraBoom->SetupAttachment(RootComponent);
	CameraBoom->TargetArmLength = 400.0f; // The camera follows at this distance behind the character	
	CameraBoom->bUsePawnControlRotation = true; // Rotate the arm based on the controller

	// Create a follow camera
	FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
	FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName); // Attach the camera to the end of the boom and let the boom adjust to match the controller orientation
	FollowCamera->bUsePawnControlRotation = false; // Camera does not rotate relative to arm

	// Note: The skeletal mesh and anim blueprint references on the Mesh component (inherited from Character) 
	// are set in the derived blueprint asset named ThirdPersonCharacter (to avoid direct content references in C++)

	// Default Stats for the Player
	level = 1;
	upgradePoints = 3;
	canLevel = false;
	openInventory = false;
	hasAttacked = false;
	isOverlappingItem = false;
	
	xp = 40.0f;
	xpToLevelUp = 100.0f;

	baseDamage = 10.0f;
	
	strength = 10;
	agility = 10;
	intelligence = 10;

	attackSpeed = 1.0f;

	baseSpellAmp = 1.0f;

	inventory.maxWeight = 100.0f;

	//currentWeapon = nullptr;

	calculateStats();

}

//////////////////////////////////////////////////////////////////////////
// Input

void AAghanim_RPGCharacter::SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent)
{
	// Set up gameplay key bindings
	check(PlayerInputComponent);
	PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
	PlayerInputComponent->BindAction("Jump", IE_Released, this, &ACharacter::StopJumping);

	PlayerInputComponent->BindAction("Sprint", IE_Pressed, this, &AAghanim_RPGCharacter::sprint);
	PlayerInputComponent->BindAction("Sprint", IE_Released, this, &AAghanim_RPGCharacter::stopSprint);

	PlayerInputComponent->BindAction("Attack", IE_Pressed, this, &AAghanim_RPGCharacter::dealDamage);

	PlayerInputComponent->BindAction("Inventory", IE_Pressed, this, &AAghanim_RPGCharacter::toggleInventory);
	PlayerInputComponent->BindAction("Equip", IE_Pressed, this, &AAghanim_RPGCharacter::eqiupItemToInv);

	PlayerInputComponent->BindAxis("Move Forward / Backward", this, &AAghanim_RPGCharacter::MoveForward);
	PlayerInputComponent->BindAxis("Move Right / Left", this, &AAghanim_RPGCharacter::MoveRight);

	// We have 2 versions of the rotation bindings to handle different kinds of devices differently
	// "turn" handles devices that provide an absolute delta, such as a mouse.
	// "turnrate" is for devices that we choose to treat as a rate of change, such as an analog joystick
	PlayerInputComponent->BindAxis("Turn Right / Left Mouse", this, &APawn::AddControllerYawInput);
	PlayerInputComponent->BindAxis("Turn Right / Left Gamepad", this, &AAghanim_RPGCharacter::TurnAtRate);
	PlayerInputComponent->BindAxis("Look Up / Down Mouse", this, &APawn::AddControllerPitchInput);
	PlayerInputComponent->BindAxis("Look Up / Down Gamepad", this, &AAghanim_RPGCharacter::LookUpAtRate);

	// handle touch devices
	PlayerInputComponent->BindTouch(IE_Pressed, this, &AAghanim_RPGCharacter::TouchStarted);
	PlayerInputComponent->BindTouch(IE_Released, this, &AAghanim_RPGCharacter::TouchStopped);
}

void AAghanim_RPGCharacter::TouchStarted(ETouchIndex::Type FingerIndex, FVector Location)
{
	Jump();
}

void AAghanim_RPGCharacter::TouchStopped(ETouchIndex::Type FingerIndex, FVector Location)
{
	StopJumping();
}

void AAghanim_RPGCharacter::TurnAtRate(float Rate)
{
	// calculate delta for this frame from the rate information
	AddControllerYawInput(Rate * TurnRateGamepad * GetWorld()->GetDeltaSeconds());
}

void AAghanim_RPGCharacter::LookUpAtRate(float Rate)
{
	// calculate delta for this frame from the rate information
	AddControllerPitchInput(Rate * TurnRateGamepad * GetWorld()->GetDeltaSeconds());
}

void AAghanim_RPGCharacter::MoveForward(float Value)
{
	if ((Controller != nullptr) && (Value != 0.0f))
	{
		// find out which way is forward
		const FRotator Rotation = Controller->GetControlRotation();
		const FRotator YawRotation(0, Rotation.Yaw, 0);

		// get forward vector
		const FVector Direction = FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X);
		AddMovementInput(Direction, Value);
	}
}

void AAghanim_RPGCharacter::MoveRight(float Value)
{
	if ((Controller != nullptr) && (Value != 0.0f))
	{
		// find out which way is right
		const FRotator Rotation = Controller->GetControlRotation();
		const FRotator YawRotation(0, Rotation.Yaw, 0);

		// get right vector 
		const FVector Direction = FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y);
		// add movement in that direction
		AddMovementInput(Direction, Value);
	}
}

void AAghanim_RPGCharacter::sprint()
{
	//UE_LOG(LogTemp.Warning, TEXT("Started Sprint."));
	GetCharacterMovement()->MaxWalkSpeed = 750.0f;
}

void AAghanim_RPGCharacter::stopSprint()
{
	//UE_LOG(LogTemp.Warning, TEXT("Stopped Sprint."));
	GetCharacterMovement()->MaxWalkSpeed = 500.0f;
}

void AAghanim_RPGCharacter::dealDamage()
{
	hasAttacked = true;
}

void AAghanim_RPGCharacter::onLevelUp()
{
	level++;
	xp -= xpToLevelUp;
	xpToLevelUp *= 2;
	upgradePoints += 3;
	calculateStats();
}

void  AAghanim_RPGCharacter::addStatStrength()
{
	if (upgradePoints > 0)
	{
		strength++;
		upgradePoints--;
	}
	calculateStats();
}
void  AAghanim_RPGCharacter::addStatAgility()
{
	if (upgradePoints > 0)
	{
		agility++;
		upgradePoints--;
	}
	calculateStats();
}
void  AAghanim_RPGCharacter::addStatIntelligence()
{
	if (upgradePoints > 0)
	{
		intelligence++;
		upgradePoints--;
	}
	calculateStats();
}

// alter growth rates based of attribute stats
void AAghanim_RPGCharacter::calculateStats()
{
	maxHealth = 10.0f * strength;
	maxStamina = 5.0f * agility;
	maxMana = 5.0f * intelligence;
	health = maxHealth;
	mana = maxMana;
	stamina = maxStamina;
	armor = 1.0f * agility;
	baseDamage = 1.5 * strength;
	damage = baseDamage;
	spellAmp = baseSpellAmp + 0.1 * intelligence;
	attackSpeed = 1.0f - 0.01 * agility;
	//damage += currentWeapon->damage;
}

void  AAghanim_RPGCharacter::takeDamage(float damageAmount)
{
	health -= damageAmount;
}

void AAghanim_RPGCharacter::toggleInventory()
{
	openInventory = !openInventory;
}

void AAghanim_RPGCharacter::updateWeapon()
{
	//damage = currentWeapon->damage;
}

void AAghanim_RPGCharacter::addToInventory(ADefaultItem* _item)
{
	if(_item)
		inventory.itemList.Add(_item);
}

void AAghanim_RPGCharacter::eqiupItemToInv()
{
	if (isOverlappingItem)
	{
		UE_LOG(LogTemp, Warning,TEXT("picked up item"));
	}
}