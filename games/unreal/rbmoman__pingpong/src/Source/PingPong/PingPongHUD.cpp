#include "PingPongHUD.h"
#include "PingPongGameMode.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/Canvas.h"
#include "Math/UnrealMathUtility.h"

void APingPongHUD::DrawHUD()
{
	Super::DrawHUD();

	if (!Canvas) return;

	ComputeField();

	APingPongGameMode* GM = Cast<APingPongGameMode>(
		UGameplayStatics::GetGameMode(GetWorld()));
	if (!GM) return;

	// 1. Black background over full canvas
	DrawRect(FLinearColor::Black, 0.f, 0.f, Canvas->SizeX, Canvas->SizeY);

	// 2. Black field area (already black, but ensures letterbox borders stay black)
	DrawRect(FLinearColor::Black, FieldL, FieldT, FieldW, FieldH);

	// 3. Center dashed divider
	DrawCenterDivider();

	// 4. Paddles
	float PlayerCX = SX(APingPongGameMode::PaddleX + APingPongGameMode::PaddleW * 0.5f);
	float AICX     = SX(1.f - APingPongGameMode::PaddleX - APingPongGameMode::PaddleW * 0.5f);

	DrawPaddle(PlayerCX, SY(GM->PlayerPaddleY), FLinearColor::White);
	DrawPaddle(AICX,     SY(GM->AIPaddleY),     FLinearColor::White);

	// 5. Ball
	float BallSX = SX(GM->BallPos.X);
	float BallSY = SY(GM->BallPos.Y);
	float BallR  = SW(APingPongGameMode::BallRadius);
	DrawBall(BallSX, BallSY, BallR, FLinearColor::Yellow);

	// 6. CRT scanlines on top
	DrawScanlines();

	// 7. Vignette
	DrawVignette();
}

void APingPongHUD::ComputeField()
{
	float CanvasW = Canvas->SizeX;
	float CanvasH = Canvas->SizeY;
	constexpr float AspectRatio = 16.f / 9.f;

	if (CanvasW / CanvasH >= AspectRatio)
	{
		FieldH = CanvasH;
		FieldW = CanvasH * AspectRatio;
	}
	else
	{
		FieldW = CanvasW;
		FieldH = CanvasW / AspectRatio;
	}

	FieldL = (CanvasW - FieldW) * 0.5f;
	FieldT = (CanvasH - FieldH) * 0.5f;
}

void APingPongHUD::DrawPaddle(float CX, float CY, const FLinearColor& Color)
{
	float HalfW = SW(APingPongGameMode::PaddleW * 0.5f);
	float HalfH = SH(APingPongGameMode::PaddleH * 0.5f);

	// Glow layers (outer to inner)
	DrawRect(FLinearColor(Color.R, Color.G, Color.B, 0.10f),
		CX - HalfW - 8.f, CY - HalfH - 8.f, (HalfW + 8.f) * 2.f, (HalfH + 8.f) * 2.f);
	DrawRect(FLinearColor(Color.R, Color.G, Color.B, 0.20f),
		CX - HalfW - 4.f, CY - HalfH - 4.f, (HalfW + 4.f) * 2.f, (HalfH + 4.f) * 2.f);

	// Solid paddle
	DrawRect(Color, CX - HalfW, CY - HalfH, HalfW * 2.f, HalfH * 2.f);
}

void APingPongHUD::DrawBall(float CX, float CY, float R, const FLinearColor& Color)
{
	// Glow layers
	DrawRect(FLinearColor(Color.R, Color.G, Color.B, 0.10f),
		CX - R - 8.f, CY - R - 8.f, (R + 8.f) * 2.f, (R + 8.f) * 2.f);
	DrawRect(FLinearColor(Color.R, Color.G, Color.B, 0.20f),
		CX - R - 4.f, CY - R - 4.f, (R + 4.f) * 2.f, (R + 4.f) * 2.f);

	// Filled circle via horizontal scanlines
	for (float dy = -R; dy <= R; dy += 1.f)
	{
		float dx = FMath::Sqrt(FMath::Max(0.f, R * R - dy * dy));
		DrawLine(CX - dx, CY + dy, CX + dx, CY + dy, Color, 1.f);
	}
}

void APingPongHUD::DrawCenterDivider()
{
	float CX     = SX(0.5f);
	float DashH  = 18.f;
	float GapH   = 12.f;
	float Y      = FieldT;
	float Bottom = FieldT + FieldH;
	bool  Draw   = true;

	while (Y < Bottom)
	{
		float SegEnd = FMath::Min(Y + (Draw ? DashH : GapH), Bottom);
		if (Draw)
		{
			DrawLine(CX, Y, CX, SegEnd, FLinearColor(0.7f, 0.7f, 0.7f, 1.f), 2.f);
		}
		Y = SegEnd;
		Draw = !Draw;
	}
}

void APingPongHUD::DrawScanlines()
{
	float Bottom = FieldT + FieldH;
	FLinearColor LineColor(0.f, 0.f, 0.f, 0.30f);
	for (float Y = FieldT; Y < Bottom; Y += 3.f)
	{
		DrawLine(FieldL, Y, FieldL + FieldW, Y, LineColor, 1.f);
	}
}

void APingPongHUD::DrawVignette()
{
	constexpr float VigW = 80.f;
	FLinearColor VigColor(0.f, 0.f, 0.f, 0.55f);

	// Left edge
	DrawRect(VigColor, FieldL, FieldT, VigW, FieldH);
	// Right edge
	DrawRect(VigColor, FieldL + FieldW - VigW, FieldT, VigW, FieldH);
	// Top edge
	DrawRect(VigColor, FieldL, FieldT, FieldW, VigW);
	// Bottom edge
	DrawRect(VigColor, FieldL, FieldT + FieldH - VigW, FieldW, VigW);
}
