#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "SeagullXPComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnXPLevelUp, int32, NewLevel);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnXPChanged, int32, Current, int32, ToNext);

UCLASS()
class USeagullXPComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	USeagullXPComponent();

	float PickupRadius = 50.f;

	UPROPERTY(BlueprintAssignable)
	FOnXPLevelUp OnLevelUp;

	UPROPERTY(BlueprintAssignable)
	FOnXPChanged OnXPChanged;
};
