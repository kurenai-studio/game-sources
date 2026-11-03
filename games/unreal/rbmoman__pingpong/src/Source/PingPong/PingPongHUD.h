#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "PingPongHUD.generated.h"

UCLASS()
class PINGPONG_API APingPongHUD : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;

private:
	// Letterboxed 16:9 field in screen pixels
	float FieldL = 0.f;
	float FieldT = 0.f;
	float FieldW = 0.f;
	float FieldH = 0.f;

	// Normalized-to-screen helpers
	float SX(float nx) const { return FieldL + nx * FieldW; }
	float SY(float ny) const { return FieldT + ny * FieldH; }
	float SW(float nw) const { return nw * FieldW; }
	float SH(float nh) const { return nh * FieldH; }

	void ComputeField();
	void DrawPaddle(float CX, float CY, const FLinearColor& Color);
	void DrawBall(float CX, float CY, float R, const FLinearColor& Color);
	void DrawScanlines();
	void DrawVignette();
	void DrawCenterDivider();
};
