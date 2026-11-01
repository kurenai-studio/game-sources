#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SeagullPoisonZone.generated.h"

class USphereComponent;

UCLASS()
class ASeagullPoisonZone : public AActor
{
	GENERATED_BODY()

public:
	ASeagullPoisonZone();
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

private:
	UPROPERTY(VisibleAnywhere)
	USphereComponent* DamageZone;

	float Lifetime = 2.5f;
	float DamageInterval = 0.5f;
	float DamageTimer = 0.f;
	int32 DamagePerTick = 5;
};
