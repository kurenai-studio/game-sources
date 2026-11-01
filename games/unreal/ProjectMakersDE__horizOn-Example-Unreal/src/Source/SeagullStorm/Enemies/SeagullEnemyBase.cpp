#include "Enemies/SeagullEnemyBase.h"
#include "Animation/SeagullSpritePlane.h"
#include "Animation/SeagullCutoutRigComponent.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Pickups/SeagullPickup_XP.h"
#include "Pickups/SeagullPickup_Health.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullStormGameMode.h"
#include "Audio/SeagullAudioManager.h"
#include "Components/SphereComponent.h"
#include "PaperFlipbook.h"
#include "PaperFlipbookComponent.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

ASeagullEnemyBase::ASeagullEnemyBase()
{
	PrimaryActorTick.bCanEverTick = true;
	Tags.Add(TEXT("Enemy"));

	CollisionComponent = CreateDefaultSubobject<USphereComponent>(TEXT("Collision"));
	CollisionComponent->SetSphereRadius(14.f);
	CollisionComponent->SetCollisionProfileName(TEXT("OverlapAllDynamic"));
	CollisionComponent->SetGenerateOverlapEvents(true);
	RootComponent = CollisionComponent;

	SpriteComponent = CreateDefaultSubobject<UPaperFlipbookComponent>(TEXT("Sprite"));
	SpriteComponent->SetupAttachment(RootComponent);
	SpriteComponent->SetRelativeRotation(SeagullSpritePlane()); // Paper2D XZ -> arena XY.
	SpriteComponent->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	SpriteComponent->SetRelativeLocation(FVector(0.f, 0.f, 2.f));
}

void ASeagullEnemyBase::BeginPlay()
{
	Super::BeginPlay();
	CollisionComponent->OnComponentBeginOverlap.AddDynamic(this, &ASeagullEnemyBase::OnOverlapBegin);
	if (CutoutRig && CutoutRig->Initialize(SeagullCutout::Character::Crab, 38.f))
	{
		SpriteComponent->SetVisibility(false);
		SpriteComponent->Stop();
	}
}

void ASeagullEnemyBase::LoadFlipbooks(const TCHAR* WalkPath, const TCHAR* DeathPath)
{
	// Cached: enemies spawn several times per second during waves.
	WalkFlipbook = SeagullAssets::LoadFlipbookCached(WalkPath);
	DeathFlipbook = SeagullAssets::LoadFlipbookCached(DeathPath);
	if (SpriteComponent && WalkFlipbook)
	{
		SpriteComponent->SetFlipbook(WalkFlipbook);
	}
}

void ASeagullEnemyBase::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (IsDead()) return;

	const FVector PreviousLocation = GetActorLocation();
	MoveTowardPlayer(DeltaTime);
	AttackTimer -= DeltaTime;
    HitFlashTimer = FMath::Max(0.f, HitFlashTimer - DeltaTime);
    if (CutoutRig && CutoutRig->IsReady())
    {
        const bool Moving = !PreviousLocation.Equals(GetActorLocation(), .001f);
        CutoutRig->UpdatePose(DeltaTime, Moving, VisualFacing, HitFlashTimer > 0.f ? SeagullColors::Orange : FLinearColor::White);
    }
    else if (SpriteComponent)
    {
        SpriteComponent->SetSpriteColor(HitFlashTimer > 0.f ? SeagullColors::Orange : FLinearColor::White);
        const float Bob = FMath::Sin(GetWorld()->GetTimeSeconds() * 7.f + GetUniqueID()) * 1.5f;
        SpriteComponent->SetRelativeLocation(FVector(0.f, 0.f, 3.f + Bob));
    }
    // Sustained contact keeps hurting: begin-overlap alone never fires again while touching.
    ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(GetPlayerPawn());
    if (Player && AttackTimer <= 0.f && FVector::DistSquared(GetActorLocation(), Player->GetActorLocation()) <= FMath::Square(CollisionComponent->GetScaledSphereRadius() + Player->CollisionComponent->GetScaledSphereRadius()))
    {
        Player->HealthComponent->TakeDamage(ContactDamage);
        AttackTimer = AttackCooldown;
        if (CutoutRig) CutoutRig->PlayAttack();
    }
}

void ASeagullEnemyBase::InitFromStats(const FSeagullEnemyStats& Stats)
{
	MaxHP = Stats.HP;
	CurrentHP = Stats.HP;
	MoveSpeed = Stats.Speed;
	ContactDamage = Stats.Damage;
	XPDrop = Stats.XPDrop;
}

void ASeagullEnemyBase::TakeDamageAmount(int32 Amount)
{
	if (IsDead()) return;

	CurrentHP -= FMath::Max(0, Amount);
	HitFlashTimer = 0.15f;
	if (CutoutRig) CutoutRig->PlayHurt();

	// Play enemy hit SFX
	UWorld* World = GetWorld();
	if (World)
	{
		ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
		if (GM && GM->AudioManager && GM->AudioManager->SFX_EnemyHit)
		{
			GM->AudioManager->PlaySFX(GM->AudioManager->SFX_EnemyHit, World);
		}
	}

	if (CurrentHP <= 0)
	{
		OnDeath();
	}
}

void ASeagullEnemyBase::MoveTowardPlayer(float DeltaTime)
{
	AActor* Player = GetPlayerPawn();
	if (!Player) return;

	FVector Dir = (Player->GetActorLocation() - GetActorLocation()).GetSafeNormal();
	FVector NewLoc = GetActorLocation() + Dir * MoveSpeed * DeltaTime;
	SetActorLocation(NewLoc);
	if (FMath::Abs(Dir.X) > KINDA_SMALL_NUMBER) VisualFacing = Dir.X < 0.f ? -1.f : 1.f;

	// Flip sprite based on horizontal direction
	if (SpriteComponent)
	{
		float FlipScale = (Dir.X < 0.0f) ? -1.0f : 1.0f;
		SpriteComponent->SetRelativeScale3D(FVector(FlipScale, 1.0f, 1.0f));
	}
}

void ASeagullEnemyBase::OnDeath()
{
	if (CutoutRig) CutoutRig->Freeze();
	// Spawn XP pickup
	UWorld* World = GetWorld();
	if (World)
	{
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		ASeagullPickup_XP* XP = World->SpawnActor<ASeagullPickup_XP>(
			ASeagullPickup_XP::StaticClass(), GetActorLocation(), FRotator::ZeroRotator, Params);
		if (XP)
		{
			XP->XPAmount = XPDrop;
		}
	}

	// Update game state
	ASeagullStormGameState* GS = World ? World->GetGameState<ASeagullStormGameState>() : nullptr;
	if (GS)
	{
		GS->AddKill();
		if (World && EnemyType != ESeagullEnemyType::Boss && GS->KillCount % 12 == 0)
		{
			FActorSpawnParameters Params;
			Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
			World->SpawnActor<ASeagullPickup_Health>(ASeagullPickup_Health::StaticClass(), GetActorLocation(), FRotator::ZeroRotator, Params);
		}
	}

	// Play the death flipbook before despawning when the asset exists
	if (SpriteComponent && DeathFlipbook)
	{
		SpriteComponent->SetFlipbook(DeathFlipbook);
		SpriteComponent->SetLooping(false);
		SpriteComponent->PlayFromStart();
		SetActorEnableCollision(false);
		SetLifeSpan(DeathDespawnDelay);
	}
	else
	{
		Destroy();
	}
}

AActor* ASeagullEnemyBase::GetPlayerPawn() const
{
	return UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
}

void ASeagullEnemyBase::OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
	UPrimitiveComponent* OtherComp, int32 OtherBodyIndex,
	bool bFromSweep, const FHitResult& SweepResult)
{
	ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(OtherActor);
	if (Player && AttackTimer <= 0.f)
	{
		Player->HealthComponent->TakeDamage(ContactDamage);
		AttackTimer = AttackCooldown;
		if (CutoutRig) CutoutRig->PlayAttack();

		// Play enemy attack SFX
		UWorld* World = GetWorld();
		if (World)
		{
			ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
			if (GM && GM->AudioManager && GM->AudioManager->SFX_EnemyAttack)
			{
				GM->AudioManager->PlaySFX(GM->AudioManager->SFX_EnemyAttack, World);
			}
		}
	}
}
