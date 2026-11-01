#pragma once

#include "CoreMinimal.h"
#include "Enemies/SeagullEnemyBase.h"
#include "SeagullEnemy_Boss.generated.h"

UCLASS()
class ASeagullEnemy_Boss : public ASeagullEnemyBase
{
	GENERATED_BODY()

public:
	ASeagullEnemy_Boss();

protected:
	virtual void MoveTowardPlayer(float DeltaTime) override;
	virtual void OnDeath() override;

private:
	float ChargeTimer = 0.f;
	float ChargeCooldown = 4.f;
	float ChargeDuration = 0.6f;
	float ChargeSpeedMultiplier = 5.f;
	bool bIsCharging = false;
	float ChargeElapsed = 0.f;
	FVector ChargeDirection = FVector::ZeroVector;
};
