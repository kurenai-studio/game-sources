#include "Enemies/SeagullEnemy_Jellyfish.h"
#include "Enemies/SeagullPoisonZone.h"
#include "SeagullStorm.h"

ASeagullEnemy_Jellyfish::ASeagullEnemy_Jellyfish()
{
	EnemyType = ESeagullEnemyType::Jellyfish;
	MoveSpeed = 60.f;
	MaxHP = 50;
	CurrentHP = 50;
	ContactDamage = 15;
	XPDrop = 20;

	LoadFlipbooks(TEXT("/Game/Flipbooks/FB_Jellyfish_Idle"), TEXT("/Game/Flipbooks/FB_Jellyfish_Death"));
}

void ASeagullEnemy_Jellyfish::OnDeath()
{
	// Spawn poison zone at death location
	UWorld* World = GetWorld();
	if (World)
	{
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		World->SpawnActor<ASeagullPoisonZone>(ASeagullPoisonZone::StaticClass(),
			GetActorLocation(), FRotator::ZeroRotator, Params);
	}

	Super::OnDeath();
}
