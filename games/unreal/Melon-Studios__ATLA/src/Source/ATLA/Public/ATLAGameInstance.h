// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"

#include "ATLAGameInstance.generated.h"

/**
 *	ATLA Game Instance Class.
 */
UCLASS()
class ATLA_API UATLAGameInstance : public UGameInstance
{
	GENERATED_BODY()
	
public:
	virtual void FinishDestroy() override;
};
