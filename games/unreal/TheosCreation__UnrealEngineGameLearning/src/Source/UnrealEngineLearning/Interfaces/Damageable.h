

#pragma once

#include "CoreMinimal.h"
#include "UObject/Interface.h"

#include "Damageable.generated.h"

// This class does not need to be modified.
UINTERFACE(MinimalAPI)
class UDamageable : public UInterface
{
	GENERATED_BODY()
};

/**
 * 
 */
class UNREALENGINELEARNING_API IDamageable
{
	GENERATED_BODY()

	// Add interface functions to this class. This is the class that will be inherited to implement this interface.
public:

	virtual void ApplyDamage(float DamageAmount) = 0;
	virtual float GetHealth() const = 0;
	virtual void SetHealth(float NewHealth) = 0;
	
};
