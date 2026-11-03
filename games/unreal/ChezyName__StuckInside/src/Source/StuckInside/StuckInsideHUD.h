// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once 

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "StuckInsideHUD.generated.h"

UCLASS()
class AStuckInsideHUD : public AHUD
{
	GENERATED_BODY()

public:
	AStuckInsideHUD();

	/** Primary draw call for the HUD */
	virtual void DrawHUD() override;

private:
	/** Crosshair asset pointer */
	class UTexture2D* CrosshairTex;

};

