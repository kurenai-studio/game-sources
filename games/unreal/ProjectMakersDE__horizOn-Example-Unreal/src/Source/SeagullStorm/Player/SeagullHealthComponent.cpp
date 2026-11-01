#include "Player/SeagullHealthComponent.h"
#include "Core/SeagullTypes.h"
#include "Core/SeagullStormGameMode.h"
#include "Audio/SeagullAudioManager.h"
#include "Kismet/GameplayStatics.h"

USeagullHealthComponent::USeagullHealthComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void USeagullHealthComponent::SetMaxHP(int32 NewMax)
{
	MaxHP = FMath::Max(1, NewMax);
	CurrentHP = MaxHP;
	OnHealthChanged.Broadcast(CurrentHP, MaxHP);
}

void USeagullHealthComponent::TakeDamage(int32 Amount)
{
	if (IsDead() || IsInvincible() || Amount <= 0) return;

	CurrentHP = FMath::Max(0, CurrentHP - Amount);
	InvincibilityTimer = SeagullConstants::InvincibilityDuration;
	OnHealthChanged.Broadcast(CurrentHP, MaxHP);

	// Play player hit SFX
	UWorld* World = GetWorld();
	if (World)
	{
		ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
		if (GM && GM->AudioManager && GM->AudioManager->SFX_PlayerHit)
		{
			GM->AudioManager->PlaySFX(GM->AudioManager->SFX_PlayerHit, World);
		}
	}

	if (CurrentHP <= 0)
	{
		OnDeath.Broadcast();
	}
}

void USeagullHealthComponent::Heal(int32 Amount)
{
	CurrentHP = FMath::Min(MaxHP, CurrentHP + Amount);
	OnHealthChanged.Broadcast(CurrentHP, MaxHP);
}

void USeagullHealthComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (InvincibilityTimer > 0.f)
	{
		InvincibilityTimer -= DeltaTime;
	}
}
