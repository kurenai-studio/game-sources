// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "ArenaHUD.generated.h"

/** One transient message drawn in the centre of the screen (wave clear, game over, ...). */
struct FArenaHudMessage
{
	FString Text;
	FLinearColor Color = FLinearColor::White;
	float ExpireTime = 0.f;
	float StartTime = 0.f;
};

/**
 * Code-only HUD: health bar, score panel, minimap, crosshair and centre messages.
 * No UMG widget assets required.
 *
 * On mobile (or when bForceMobileControls is on) the layout switches to a touch
 * layout and the virtual stick / buttons are drawn here, matching the touch zones
 * defined in ArenaPlayerController.cpp.
 */
UCLASS()
class ARENARUNNER_API AArenaHUD : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;

	/** Queues a centred message. Called by the game mode. */
	void ShowMessage(const FString& Message, FLinearColor Color, float Duration = 2.5f);

	/** Force the touch layout on desktop builds (useful for testing in PIE). */
	UPROPERTY(EditDefaultsOnly, Category = "HUD")
	bool bForceMobileControls = false;

private:
	void DrawHealthBar();
	void DrawScorePanel();
	void DrawMinimap();
	void DrawMessages();
	void DrawCrosshair();
	void DrawDangerVignette();
	void DrawMobileControls();
	void DrawFilledCircle(const FVector2D& Center, float Radius, const FLinearColor& Color, int32 Sides = 28);
	void DrawRing(const FVector2D& Center, float Radius, const FLinearColor& Color, float Thickness, int32 Segments = 40);
	void DrawCenteredText(const FString& Text, const FVector2D& Center, const FLinearColor& Color, UFont* Font, float Scale);

	void DrawTextShadowed(const FString& Text, float X, float Y, const FLinearColor& Color, UFont* Font, float Scale = 1.f);

	bool UseMobileLayout() const;
	float GetHudScale() const;

	TArray<FArenaHudMessage> Messages;
};
