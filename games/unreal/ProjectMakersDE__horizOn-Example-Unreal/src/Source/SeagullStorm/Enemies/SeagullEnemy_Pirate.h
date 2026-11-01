#pragma once

#include "CoreMinimal.h"
#include "Enemies/SeagullEnemyBase.h"
#include "SeagullEnemy_Pirate.generated.h"

UCLASS()
class ASeagullEnemy_Pirate : public ASeagullEnemyBase
{
	GENERATED_BODY()

public:
	ASeagullEnemy_Pirate();

protected:
	virtual void MoveTowardPlayer(float DeltaTime) override;

private:
	float ZigzagTimer = 0.f;
	float ZigzagOffset = 0.f;
};
