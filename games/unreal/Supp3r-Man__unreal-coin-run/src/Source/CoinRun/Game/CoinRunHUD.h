#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "CoinRunHUD.generated.h"

/** Draws score, health, time, combo, dash cooldown and the pause / game over screens with the engine's default font. */
UCLASS()
class COINRUN_API ACoinRunHUD : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;

private:
	void DrawCentered(const FString& Text, float Y, const FLinearColor& Color, float Scale);
};
