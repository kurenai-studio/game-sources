#include "Enemies/SeagullEnemy_Crab.h"
#include "Animation/SeagullCutoutRigComponent.h"

ASeagullEnemy_Crab::ASeagullEnemy_Crab()
{
	EnemyType = ESeagullEnemyType::Crab;
	// Default stats (overridden by InitFromStats)
	MoveSpeed = 40.f;
	MaxHP = 30;
	CurrentHP = 30;
	ContactDamage = 10;
	XPDrop = 10;

	LoadFlipbooks(TEXT("/Game/Flipbooks/FB_Crab_Walk"), TEXT("/Game/Flipbooks/FB_Crab_Death"));
	CutoutRig = CreateDefaultSubobject<USeagullCutoutRigComponent>(TEXT("CutoutRig"));
	CutoutRig->SetupAttachment(RootComponent);
}
