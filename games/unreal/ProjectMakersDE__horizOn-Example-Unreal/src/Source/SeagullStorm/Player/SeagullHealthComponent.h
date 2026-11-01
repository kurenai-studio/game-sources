#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "SeagullHealthComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnPlayerDeath);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnHealthChanged, int32, Current, int32, Max);

UCLASS()
class USeagullHealthComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	USeagullHealthComponent();

	void SetMaxHP(int32 NewMax);
	void TakeDamage(int32 Amount);
	void Heal(int32 Amount);
	bool IsDead() const { return CurrentHP <= 0; }
	bool IsInvincible() const { return InvincibilityTimer > 0.f; }

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UPROPERTY()
	int32 MaxHP = 100;

	UPROPERTY()
	int32 CurrentHP = 100;

	UPROPERTY(BlueprintAssignable)
	FOnPlayerDeath OnDeath;

	UPROPERTY(BlueprintAssignable)
	FOnHealthChanged OnHealthChanged;

private:
	float InvincibilityTimer = 0.f;
};
