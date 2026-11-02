// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaCharacter.h"

#include "ArenaGameMode.h"

#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

AArenaCharacter::AArenaCharacter()
{
	PrimaryActorTick.bCanEverTick = true;

	GetCapsuleComponent()->InitCapsuleSize(42.f, 96.f);

	bUseControllerRotationPitch = false;
	bUseControllerRotationYaw = false;
	bUseControllerRotationRoll = false;

	UCharacterMovementComponent* MoveComp = GetCharacterMovement();
	MoveComp->bOrientRotationToMovement = true;
	MoveComp->RotationRate = FRotator(0.f, 620.f, 0.f);
	MoveComp->JumpZVelocity = 640.f;
	MoveComp->AirControl = 0.40f;
	MoveComp->GravityScale = 1.25f;
	MoveComp->BrakingDecelerationWalking = 2200.f;
	MoveComp->MaxWalkSpeed = WalkSpeed;

	CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
	CameraBoom->SetupAttachment(RootComponent);
	CameraBoom->TargetArmLength = 400.f;
	CameraBoom->SocketOffset = FVector(0.f, 45.f, 80.f);
	CameraBoom->bUsePawnControlRotation = true;
	CameraBoom->bEnableCameraLag = true;
	CameraBoom->CameraLagSpeed = 14.f;
	CameraBoom->bEnableCameraRotationLag = true;
	CameraBoom->CameraRotationLagSpeed = 18.f;

	FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
	FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
	FollowCamera->bUsePawnControlRotation = false;
	FollowCamera->FieldOfView = 95.f;

	// Engine primitives keep the project asset-free.
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));

	BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
	BodyMesh->SetupAttachment(GetCapsuleComponent());
	BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	BodyMesh->SetGenerateOverlapEvents(false);
	BodyMesh->SetRelativeLocation(FVector(0.f, 0.f, -12.f));
	BodyMesh->SetRelativeScale3D(FVector(0.80f, 0.80f, 1.70f));
	if (CylinderMesh.Succeeded())
	{
		BodyMesh->SetStaticMesh(CylinderMesh.Object);
	}

	HeadMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("HeadMesh"));
	HeadMesh->SetupAttachment(GetCapsuleComponent());
	HeadMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	HeadMesh->SetGenerateOverlapEvents(false);
	HeadMesh->SetRelativeLocation(FVector(0.f, 0.f, 74.f));
	HeadMesh->SetRelativeScale3D(FVector(0.50f));
	if (SphereMesh.Succeeded())
	{
		HeadMesh->SetStaticMesh(SphereMesh.Object);
	}
}

void AArenaCharacter::BeginPlay()
{
	Super::BeginPlay();

	Health = MaxHealth;
	GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;

	if (BodyMesh)
	{
		if (UMaterialInterface* BaseMaterial = BodyMesh->GetMaterial(0))
		{
			BodyMaterial = UMaterialInstanceDynamic::Create(BaseMaterial, this);
			if (BodyMaterial)
			{
				BodyMaterial->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.05f, 0.42f, 0.95f));
				BodyMesh->SetMaterial(0, BodyMaterial);
			}
		}
	}

	// Snap to the arena spawn point. This also makes the project playable inside an
	// empty level that has no PlayerStart actor.
	if (UWorld* World = GetWorld())
	{
		if (AArenaGameMode* GameMode = World->GetAuthGameMode<AArenaGameMode>())
		{
			SetActorLocation(GameMode->GetPlayerSpawnLocation(), false, nullptr, ETeleportType::TeleportPhysics);
		}
	}
}

void AArenaCharacter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (bDead || !GetWorld())
	{
		return;
	}

	const float Now = GetWorld()->GetTimeSeconds();
	if (Health < MaxHealth && (Now - LastDamageTime) > HealthRegenDelay)
	{
		Health = FMath::Min(MaxHealth, Health + HealthRegenPerSecond * DeltaSeconds);
	}
}

void AArenaCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	if (!PlayerInputComponent)
	{
		return;
	}

	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AArenaCharacter::MoveForward);
	PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AArenaCharacter::MoveRight);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AArenaCharacter::Turn);
	PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AArenaCharacter::LookUp);

	PlayerInputComponent->BindAction(TEXT("Jump"), IE_Pressed, this, &AArenaCharacter::DoJump);
	PlayerInputComponent->BindAction(TEXT("Jump"), IE_Released, this, &AArenaCharacter::StopJump);
	PlayerInputComponent->BindAction(TEXT("Sprint"), IE_Pressed, this, &AArenaCharacter::BeginSprint);
	PlayerInputComponent->BindAction(TEXT("Sprint"), IE_Released, this, &AArenaCharacter::EndSprint);
}

// ---------------------------------------------------------------------------
// Movement
// ---------------------------------------------------------------------------

void AArenaCharacter::MoveForward(float Value)
{
	if (bDead || FMath::IsNearlyZero(Value) || !Controller)
	{
		return;
	}

	const FRotator YawOnly(0.f, Controller->GetControlRotation().Yaw, 0.f);
	AddMovementInput(FRotationMatrix(YawOnly).GetUnitAxis(EAxis::X), Value);
}

void AArenaCharacter::MoveRight(float Value)
{
	if (bDead || FMath::IsNearlyZero(Value) || !Controller)
	{
		return;
	}

	const FRotator YawOnly(0.f, Controller->GetControlRotation().Yaw, 0.f);
	AddMovementInput(FRotationMatrix(YawOnly).GetUnitAxis(EAxis::Y), Value);
}

void AArenaCharacter::Turn(float Value)
{
	if (bDead)
	{
		return;
	}

	AddControllerYawInput(Value);
}

void AArenaCharacter::LookUp(float Value)
{
	if (bDead)
	{
		return;
	}

	AddControllerPitchInput(Value);
}

void AArenaCharacter::BeginSprint()
{
	SetSprinting(true);
}

void AArenaCharacter::EndSprint()
{
	SetSprinting(false);
}

void AArenaCharacter::SetSprinting(bool bEnabled)
{
	bSprinting = bEnabled;
	if (!bDead)
	{
		GetCharacterMovement()->MaxWalkSpeed = bEnabled ? SprintSpeed : WalkSpeed;
	}
}

void AArenaCharacter::AddTouchMoveInput(float ForwardAmount, float RightAmount)
{
	if (bDead || !Controller)
	{
		return;
	}

	if (FMath::IsNearlyZero(ForwardAmount) && FMath::IsNearlyZero(RightAmount))
	{
		return;
	}

	const FRotator YawOnly(0.f, Controller->GetControlRotation().Yaw, 0.f);
	const FRotationMatrix YawMatrix(YawOnly);
	AddMovementInput(YawMatrix.GetUnitAxis(EAxis::X), ForwardAmount);
	AddMovementInput(YawMatrix.GetUnitAxis(EAxis::Y), RightAmount);
}

void AArenaCharacter::TouchJump()
{
	if (!bDead)
	{
		Jump();
	}
}

void AArenaCharacter::DoJump()
{
	if (!bDead)
	{
		Jump();
	}
}

void AArenaCharacter::StopJump()
{
	StopJumping();
}

// ---------------------------------------------------------------------------
// Damage / run state
// ---------------------------------------------------------------------------

float AArenaCharacter::TakeDamage(float DamageAmount, const FDamageEvent& DamageEvent, AController* EventInstigator, AActor* DamageCauser)
{
	const float ActualDamage = Super::TakeDamage(DamageAmount, DamageEvent, EventInstigator, DamageCauser);
	if (bDead || ActualDamage <= 0.f || !GetWorld())
	{
		return 0.f;
	}

	const float Now = GetWorld()->GetTimeSeconds();
	if (Now - LastDamageTime < DamageCooldown)
	{
		return 0.f;
	}

	LastDamageTime = Now;
	Health = FMath::Max(0.f, Health - ActualDamage);

	if (DamageCauser)
	{
		FVector Away = GetActorLocation() - DamageCauser->GetActorLocation();
		Away.Z = 0.f;
		if (Away.IsNearlyZero())
		{
			Away = FVector::ForwardVector;
		}
		LaunchCharacter(Away.GetSafeNormal() * KnockBackStrength + FVector(0.f, 0.f, 180.f), false, false);
	}

	if (Health <= 0.f)
	{
		bDead = true;
		bSprinting = false;
		GetCharacterMovement()->DisableMovement();

		if (AArenaGameMode* GameMode = GetWorld()->GetAuthGameMode<AArenaGameMode>())
		{
			GameMode->HandlePlayerDied();
		}
	}

	return ActualDamage;
}

void AArenaCharacter::ResetForRun(const FVector& Location, const FRotator& Rotation)
{
	bDead = false;
	bSprinting = false;
	Health = MaxHealth;
	LastDamageTime = -1000.f;

	GetCharacterMovement()->SetMovementMode(MOVE_Walking);
	GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;

	SetActorLocationAndRotation(Location, Rotation, false, nullptr, ETeleportType::TeleportPhysics);
	GetCharacterMovement()->StopMovementImmediately();
	SetActorEnableCollision(true);
}
