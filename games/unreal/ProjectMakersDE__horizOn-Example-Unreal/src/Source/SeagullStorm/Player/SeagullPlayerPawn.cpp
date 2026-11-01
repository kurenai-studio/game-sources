#include "Player/SeagullPlayerPawn.h"
#include "Animation/SeagullSpritePlane.h"
#include "Animation/SeagullCutoutRigComponent.h"
#include "Player/SeagullHealthComponent.h"
#include "Player/SeagullXPComponent.h"
#include "Weapons/SeagullWeaponManager.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullPlayerController.h"
#include "Data/SeagullConfigCache.h"
#include "Components/SphereComponent.h"
#include "PaperFlipbook.h"
#include "PaperFlipbookComponent.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Core/SeagullTypes.h"
#include "SeagullStorm.h"

ASeagullPlayerPawn::ASeagullPlayerPawn()
{
	PrimaryActorTick.bCanEverTick = true;
	Tags.Add(TEXT("PlayerPawn"));

	// Collision
	CollisionComponent = CreateDefaultSubobject<USphereComponent>(TEXT("Collision"));
	CollisionComponent->SetSphereRadius(16.f);
	CollisionComponent->SetCollisionProfileName(TEXT("Pawn"));
	RootComponent = CollisionComponent;

	// Sprite
	SpriteComponent = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Sprite"));
	SpriteComponent->SetupAttachment(RootComponent);
	SpriteComponent->SetRelativeRotation(SeagullSpritePlane()); // Paper2D XZ -> arena XY.
	SpriteComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	SpriteComponent->SetRelativeLocation(FVector(0.f, 0.f, 2.f));
	CutoutRig = CreateDefaultSubobject<USeagullCutoutRigComponent>(TEXT("CutoutRig"));
	CutoutRig->SetupAttachment(RootComponent);

	// Flipbooks (assets are created in the editor from seagull.png, see EDITOR_SETUP.md;
	// all loads are null-guarded so the game runs without them)
	IdleFlipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Seagull_Idle"));
	WalkFlipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Seagull_Walk"));
	HurtFlipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Seagull_Hurt"));
	DeathFlipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Seagull_Death"));
	if (IdleFlipbook)
	{
		SpriteComponent->SetFlipbook(IdleFlipbook);
	}

	// Movement
	MovementComponent = CreateDefaultSubobject<UFloatingPawnMovement>(TEXT("Movement"));
	MovementComponent->MaxSpeed = BaseSpeed;
	MovementComponent->Acceleration = 2000.f;
	MovementComponent->Deceleration = 2000.f;

	// Camera
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArm"));
	SpringArm->SetupAttachment(RootComponent);
	SpringArm->TargetArmLength = 500.f;
	SpringArm->SetRelativeRotation(FRotator(-90.f, -90.f, 0.f)); // Camera right is +X, up is -Y (SeagullScreenUpY).
	SpringArm->bDoCollisionTest = false;
	SpringArm->bInheritPitch = false;
	SpringArm->bInheritYaw = false;
	SpringArm->bInheritRoll = false;

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
	Camera->ProjectionMode = ECameraProjectionMode::Orthographic;
	Camera->OrthoWidth = 720.f;
	Camera->bAutoCalculateOrthoPlanes = true;

	// Components
	HealthComponent = CreateDefaultSubobject<USeagullHealthComponent>(TEXT("Health"));
	XPComponent = CreateDefaultSubobject<USeagullXPComponent>(TEXT("XP"));
	WeaponManager = CreateDefaultSubobject<USeagullWeaponManager>(TEXT("WeaponManager"));
}

void ASeagullPlayerPawn::BeginPlay()
{
	Super::BeginPlay();
	HealthComponent->OnDeath.AddDynamic(this, &ASeagullPlayerPawn::OnDeath);
	HealthComponent->OnHealthChanged.AddDynamic(this, &ASeagullPlayerPawn::OnHealthChangedHandler);
	ApplyUpgrades();
	LastKnownHP = HealthComponent->CurrentHP;
	if (CutoutRig->Initialize(SeagullCutout::Character::Gull, 44.f))
	{
		SpriteComponent->SetVisibility(false);
		SpriteComponent->Stop();
	}
}

void ASeagullPlayerPawn::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// Get movement input from controller
	ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(GetController());
	if (PC)
	{
		FVector2D Input = PC->GetMoveInput();
		if (!Input.IsNearlyZero())
		{
			FVector WorldDir(Input.X, Input.Y * SeagullScreenUpY, 0.f);
			WorldDir.Normalize();
			AddMovementInput(WorldDir, 1.0f);
			LastMoveDirection = FVector2D(WorldDir.X, WorldDir.Y);

			// Flip sprite based on horizontal direction
			if (SpriteComponent && LastMoveDirection.X != 0.0f)
			{
				float FlipScale = (LastMoveDirection.X < 0.0f) ? -1.0f : 1.0f;
				SpriteComponent->SetRelativeScale3D(FVector(FlipScale, 1.0f, 1.0f));
			}
		}
	}

	// Clamp to arena bounds
	FVector Pos = GetActorLocation();
	float HalfW = SeagullConstants::ArenaWidth * 0.5f;
	float HalfH = SeagullConstants::ArenaHeight * 0.5f;
	Pos.X = FMath::Clamp(Pos.X, -HalfW, HalfW);
	Pos.Y = FMath::Clamp(Pos.Y, -HalfH, HalfH);
	SetActorLocation(Pos);

    if (CutoutRig && CutoutRig->IsReady())
    {
        const bool Moving = MovementComponent && MovementComponent->Velocity.SizeSquared() > 25.f;
        CutoutRig->UpdatePose(DeltaTime, Moving, SpriteComponent->GetRelativeScale3D().X,
            HealthComponent->IsInvincible() ? SeagullColors::Orange : FLinearColor::White);
    }
    else if (SpriteComponent)
    {
        const bool Moving = MovementComponent && MovementComponent->Velocity.SizeSquared() > 25.f;
        const float Bob = FMath::Sin(GetWorld()->GetTimeSeconds() * (Moving ? 14.f : 5.f)) * (Moving ? 2.f : 0.7f);
        SpriteComponent->SetRelativeLocation(FVector(0.f, 0.f, 4.f + Bob));
        SpriteComponent->SetSpriteColor(HealthComponent->IsInvincible() ? SeagullColors::Orange : FLinearColor::White);
    }
    UpdateFlipbookState(DeltaTime);
}

void ASeagullPlayerPawn::UpdateFlipbookState(float DeltaTime)
{
	if (!SpriteComponent) return;

	// Death animation wins and is never overridden
	if (HealthComponent && HealthComponent->IsDead()) return;

	// Brief hurt flash after taking damage
	if (HurtFlashTimer > 0.f)
	{
		HurtFlashTimer -= DeltaTime;
		return;
	}

	// Idle/Walk by movement speed
	const bool bMoving = MovementComponent && MovementComponent->Velocity.SizeSquared() > 25.f;
	UPaperFlipbook* Desired = bMoving ? WalkFlipbook : IdleFlipbook;
	if (Desired && SpriteComponent->GetFlipbook() != Desired)
	{
		SpriteComponent->SetFlipbook(Desired);
	}
}

void ASeagullPlayerPawn::OnHealthChangedHandler(int32 Current, int32 Max)
{
	if (Current < LastKnownHP)
	{
		if (CutoutRig) CutoutRig->PlayHurt();
		if (SpriteComponent && HurtFlipbook) SpriteComponent->SetFlipbook(HurtFlipbook);
		HurtFlashTimer = 0.3f;
	}
	LastKnownHP = Current;
}

void ASeagullPlayerPawn::PlayAttackPose()
{
	if (CutoutRig) CutoutRig->PlayAttack();
}

void ASeagullPlayerPawn::ApplyUpgrades()
{
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(GetGameInstance());
	if (!GI || !GI->GetConfigCache()) return;

	USeagullConfigCache* Config = GI->GetConfigCache();

	// Speed
	float SpeedMult = Config->GetUpgradeValue(TEXT("speed"), GI->SaveData.GetUpgradeLevel(TEXT("speed")));
	MovementComponent->MaxSpeed = BaseSpeed * SpeedMult;

	// HP
	int32 MaxHP = static_cast<int32>(Config->GetUpgradeValue(TEXT("hp"), GI->SaveData.GetUpgradeLevel(TEXT("hp"))));
	HealthComponent->SetMaxHP(MaxHP);

	// Magnet
	float MagnetRange = Config->GetUpgradeValue(TEXT("magnet"), GI->SaveData.GetUpgradeLevel(TEXT("magnet")));
	XPComponent->PickupRadius = MagnetRange;

	// Damage multiplier applied in weapon manager
	float DamageMult = Config->GetUpgradeValue(TEXT("damage"), GI->SaveData.GetUpgradeLevel(TEXT("damage")));
	WeaponManager->DamageMultiplier = DamageMult;
	WeaponManager->UpdateDamageMultipliers();
}

void ASeagullPlayerPawn::OnDeath()
{
	UE_LOG(LogSeagullStorm, Log, TEXT("Player died!"));
	if (CutoutRig) CutoutRig->Freeze();

	// Death flipbook hook: plays until the run actors are cleaned up
	if (SpriteComponent && DeathFlipbook)
	{
		SpriteComponent->SetFlipbook(DeathFlipbook);
		SpriteComponent->SetLooping(false);
		SpriteComponent->PlayFromStart();
	}

	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(GetWorld()->GetAuthGameMode());
	if (GM)
	{
		GM->EndRun(true);
	}
}
