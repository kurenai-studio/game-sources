#pragma once

#include "CoreMinimal.h"
#include "Enemies/SeagullEnemyBase.h"
#include "SeagullEnemy_Jellyfish.generated.h"

UCLASS()
class ASeagullEnemy_Jellyfish : public ASeagullEnemyBase
{
	GENERATED_BODY()

public:
	ASeagullEnemy_Jellyfish();

protected:
	virtual void OnDeath() override;
};
