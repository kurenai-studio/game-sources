#include "Enemies/SeagullEnemy_Boss.h"
#include "Core/SeagullStormGameMode.h"
#include "SeagullStorm.h"
#include "Components/SphereComponent.h"
#include "PaperFlipbookComponent.h"

ASeagullEnemy_Boss::ASeagullEnemy_Boss()
{
	EnemyType = ESeagullEnemyType::Boss;
	MoveSpeed = 30.f;
	MaxHP = 500;
	CurrentHP = 500;
	ContactDamage = 30;
	XPDrop = 100;

	// Larger collision for 64x64 boss
	if (CollisionComponent)
	{
		CollisionComponent->SetSphereRadius(28.f);
	}

	LoadFlipbooks(TEXT("/Game/Flipbooks/FB_Boss_Idle"), TEXT("/Game/Flipbooks/FB_Boss_Death"));
}

void ASeagullEnemy_Boss::MoveTowardPlayer(float DeltaTime)
{
	AActor* Player = GetPlayerPawn();
	if (!Player) return;

	if (bIsCharging)
	{
		// Dash in the locked charge direction at high speed
		ChargeElapsed += DeltaTime;
		FVector NewLoc = GetActorLocation() + ChargeDirection * MoveSpeed * ChargeSpeedMultiplier * DeltaTime;
		SetActorLocation(NewLoc);

		if (ChargeElapsed >= ChargeDuration)
		{
			bIsCharging = false;
			ChargeTimer = 0.f;
		}
	}
	else
	{
		// Slow movement toward player
		FVector ToPlayer = (Player->GetActorLocation() - GetActorLocation()).GetSafeNormal();
		FVector NewLoc = GetActorLocation() + ToPlayer * MoveSpeed * DeltaTime;
		SetActorLocation(NewLoc);

		// Flip sprite based on horizontal direction toward player
		if (SpriteComponent)
		{
			float FlipScale = (ToPlayer.X < 0.0f) ? -1.0f : 1.0f;
			SpriteComponent->SetRelativeScale3D(FVector(FlipScale, 1.0f, 1.0f));
		}

		// Count down to next charge
		ChargeTimer += DeltaTime;
		if (ChargeTimer >= ChargeCooldown)
		{
			bIsCharging = true;
			ChargeElapsed = 0.f;
			ChargeDirection = ToPlayer;
		}
	}
}

void ASeagullEnemy_Boss::OnDeath()
{
	UE_LOG(LogSeagullStorm, Log, TEXT("Boss defeated!"));

	Super::OnDeath();

	// Boss death ends the run successfully
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(GetWorld()->GetAuthGameMode());
	if (GM)
	{
		GM->EndRun(false);
	}

}
