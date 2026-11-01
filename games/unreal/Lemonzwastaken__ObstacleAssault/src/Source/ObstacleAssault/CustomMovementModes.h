#pragma once
#include "CustomMovementModes.generated.h"


UENUM(BlueprintType)
enum ECustomMovementMode : int
{
	CMOVE_WallRunning  UMETA(DisplayName = "WallRunning"),

	CMOVE_Grinding		UMETA(DisplayName = "Grinding"),

	CMOVE_Dashing		UMETA(DisplayName = "Dashing"),

	CMOVE_MAX		   UMETA(Hidden),
};
