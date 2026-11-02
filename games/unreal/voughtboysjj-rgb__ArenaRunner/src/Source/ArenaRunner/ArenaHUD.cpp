// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaHUD.h"

#include "ArenaCharacter.h"
#include "ArenaCollectible.h"
#include "ArenaGameState.h"
#include "ArenaHunter.h"
#include "ArenaPlayerController.h"

#include "CanvasItem.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Engine/Font.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"

namespace ArenaHudStyle
{
	static const FLinearColor Panel(0.02f, 0.03f, 0.05f, 0.72f);
	static const FLinearColor PanelEdge(0.15f, 0.55f, 1.0f, 0.85f);
	static const FLinearColor HealthHigh(0.10f, 0.95f, 0.45f, 1.f);
	static const FLinearColor HealthMid(1.0f, 0.72f, 0.10f, 1.f);
	static const FLinearColor HealthLow(1.0f, 0.18f, 0.18f, 1.f);
	static const FLinearColor Accent(0.25f, 0.85f, 1.0f, 1.f);
	static const FLinearColor Text(0.94f, 0.97f, 1.0f, 1.f);
	static const FLinearColor SubText(0.55f, 0.62f, 0.72f, 1.f);
	static const FLinearColor TouchGlass(0.75f, 0.90f, 1.0f, 0.16f);
	static const FLinearColor TouchGlassStrong(0.75f, 0.90f, 1.0f, 0.34f);
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

bool AArenaHUD::UseMobileLayout() const
{
#if PLATFORM_ANDROID || PLATFORM_IOS
	return true;
#else
	return bForceMobileControls;
#endif
}

float AArenaHUD::GetHudScale() const
{
	if (!Canvas)
	{
		return 1.f;
	}

	// Scale everything from a 1080p reference so the HUD stays readable on phones.
	return FMath::Clamp(Canvas->ClipY / ArenaTouch::DesignHeight, 0.55f, 1.8f);
}

void AArenaHUD::DrawHUD()
{
	Super::DrawHUD();

	if (!Canvas || !PlayerOwner)
	{
		return;
	}

	DrawScorePanel();
	DrawHealthBar();
	DrawMinimap();
	DrawMessages();
	DrawDangerVignette();

	if (UseMobileLayout())
	{
		DrawMobileControls();
	}
	else
	{
		DrawCrosshair();
	}
}

void AArenaHUD::DrawFilledCircle(const FVector2D& Center, float Radius, const FLinearColor& Color, int32 Sides)
{
	if (!Canvas)
	{
		return;
	}

	FCanvasNGonItem Circle(
		static_cast<float>(Center.X),
		static_cast<float>(Center.Y),
		Radius,
		FMath::Clamp(Sides, 3, 64),
		Color);
	Canvas->DrawItem(Circle);
}

void AArenaHUD::DrawRing(const FVector2D& Center, float Radius, const FLinearColor& Color, float Thickness, int32 Segments)
{
	const int32 Steps = FMath::Max(8, Segments);
	FVector2D Previous = Center + FVector2D(Radius, 0.f);

	for (int32 Index = 1; Index <= Steps; ++Index)
	{
		const float Angle = (2.f * PI * static_cast<float>(Index)) / static_cast<float>(Steps);
		const FVector2D Current = Center + FVector2D(FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * Radius);
		DrawLine(static_cast<float>(Previous.X), static_cast<float>(Previous.Y),
			static_cast<float>(Current.X), static_cast<float>(Current.Y), Color, Thickness);
		Previous = Current;
	}
}

void AArenaHUD::DrawCenteredText(const FString& Text, const FVector2D& Center, const FLinearColor& Color, UFont* Font, float Scale)
{
	if (!Font)
	{
		return;
	}

	float TextW = 0.f;
	float TextH = 0.f;
	GetTextSize(Text, TextW, TextH, Font, Scale);
	DrawTextShadowed(Text, static_cast<float>(Center.X) - TextW * 0.5f,
		static_cast<float>(Center.Y) - TextH * 0.5f, Color, Font, Scale);
}

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

void AArenaHUD::DrawHealthBar()
{
	const AArenaCharacter* Character = PlayerOwner ? Cast<AArenaCharacter>(PlayerOwner->GetPawn()) : nullptr;
	if (!Character)
	{
		return;
	}

	const float S = GetHudScale();
	UFont* Font = GEngine ? GEngine->GetMediumFont() : nullptr;

	const float BarX = 42.f * S;
	// On mobile the bottom-left corner belongs to the virtual stick.
	const float BarY = Canvas->ClipY - (UseMobileLayout() ? 320.f : 96.f) * S;
	const float BarW = 340.f * S;
	const float BarH = 22.f * S;

	DrawRect(ArenaHudStyle::Panel, BarX - 10.f * S, BarY - 26.f * S, BarW + 20.f * S, BarH + 44.f * S);
	DrawTextShadowed(TEXT("VITALS"), BarX, BarY - 22.f * S, ArenaHudStyle::SubText, Font, 0.85f * S);
	DrawRect(FLinearColor(0.08f, 0.10f, 0.13f, 1.f), BarX, BarY, BarW, BarH);

	const float Percent = Character->GetHealthPercent();
	FLinearColor Fill = ArenaHudStyle::HealthHigh;
	if (Percent < 0.3f)
	{
		Fill = ArenaHudStyle::HealthLow;
	}
	else if (Percent < 0.6f)
	{
		Fill = ArenaHudStyle::HealthMid;
	}

	DrawRect(Fill, BarX, BarY, BarW * Percent, BarH);

	for (int32 Tick = 1; Tick < 10; ++Tick)
	{
		const float TickX = BarX + (BarW / 10.f) * static_cast<float>(Tick);
		DrawLine(TickX, BarY, TickX, BarY + BarH, FLinearColor(0.f, 0.f, 0.f, 0.35f), 1.f);
	}

	DrawLine(BarX, BarY, BarX + BarW, BarY, ArenaHudStyle::PanelEdge, 1.5f);
	DrawLine(BarX, BarY + BarH, BarX + BarW, BarY + BarH, ArenaHudStyle::PanelEdge, 1.5f);

	const FString HealthText = FString::Printf(
		TEXT("%d / %d"), FMath::CeilToInt(Character->GetHealth()), FMath::CeilToInt(Character->GetMaxHealth()));
	DrawTextShadowed(HealthText, BarX + BarW + 18.f * S, BarY + 2.f * S, ArenaHudStyle::Text, Font, 0.9f * S);

	if (Character->IsSprinting())
	{
		DrawTextShadowed(TEXT("SPRINT"), BarX, BarY + BarH + 6.f * S, ArenaHudStyle::Accent, Font, 0.8f * S);
	}
}

// ---------------------------------------------------------------------------
// Score panel
// ---------------------------------------------------------------------------

void AArenaHUD::DrawScorePanel()
{
	const AArenaGameState* ArenaState = GetWorld() ? GetWorld()->GetGameState<AArenaGameState>() : nullptr;
	if (!ArenaState)
	{
		return;
	}

	const float S = GetHudScale();
	UFont* Font = GEngine ? GEngine->GetLargeFont() : nullptr;
	UFont* SmallFont = GEngine ? GEngine->GetMediumFont() : nullptr;

	const float PanelW = 260.f * S;
	const float PanelH = 168.f * S;
	const float PanelX = Canvas->ClipX - PanelW - 36.f * S;
	const float PanelY = 32.f * S;

	DrawRect(ArenaHudStyle::Panel, PanelX, PanelY, PanelW, PanelH);
	DrawLine(PanelX, PanelY, PanelX + PanelW, PanelY, ArenaHudStyle::PanelEdge, 2.f);
	DrawLine(PanelX, PanelY, PanelX, PanelY + PanelH, ArenaHudStyle::PanelEdge, 2.f);

	DrawTextShadowed(TEXT("ARENA RUNNER"), PanelX + 16.f * S, PanelY + 10.f * S, ArenaHudStyle::Accent, SmallFont, 0.85f * S);
	DrawTextShadowed(FString::Printf(TEXT("%06d"), ArenaState->Score), PanelX + 16.f * S, PanelY + 30.f * S, ArenaHudStyle::Text, Font, 1.0f * S);

	DrawTextShadowed(FString::Printf(TEXT("WAVE %d"), ArenaState->Wave),
		PanelX + 16.f * S, PanelY + 76.f * S, ArenaHudStyle::Text, SmallFont, 0.9f * S);

	DrawTextShadowed(FString::Printf(TEXT("CORES %d / %d"), ArenaState->Collected, ArenaState->TotalCollectibles),
		PanelX + 16.f * S, PanelY + 98.f * S, ArenaHudStyle::SubText, SmallFont, 0.9f * S);

	DrawTextShadowed(FString::Printf(TEXT("BEST %d"), ArenaState->BestScore),
		PanelX + 16.f * S, PanelY + 120.f * S, ArenaHudStyle::SubText, SmallFont, 0.9f * S);
}

// ---------------------------------------------------------------------------
// Minimap
// ---------------------------------------------------------------------------

void AArenaHUD::DrawMinimap()
{
	UWorld* World = GetWorld();
	const AArenaCharacter* Character = PlayerOwner ? Cast<AArenaCharacter>(PlayerOwner->GetPawn()) : nullptr;
	if (!World || !Character)
	{
		return;
	}

	const float S = GetHudScale();
	const bool bMobile = UseMobileLayout();

	const float MapSize = (bMobile ? 120.f : 150.f) * S;
	// Desktop: bottom-right. Mobile: top-left (the touch buttons own the bottom corners).
	const float MapX = bMobile ? 36.f * S : Canvas->ClipX - MapSize - 40.f * S;
	const float MapY = bMobile ? 32.f * S : Canvas->ClipY - MapSize - 40.f * S;
	const float CenterX = MapX + MapSize * 0.5f;
	const float CenterY = MapY + MapSize * 0.5f;

	const float WorldRadius = 2100.f;
	const float Scale = (MapSize * 0.5f) / WorldRadius;

	DrawRect(ArenaHudStyle::Panel, MapX, MapY, MapSize, MapSize);

	for (int32 Grid = 1; Grid < 4; ++Grid)
	{
		const float Offset = (MapSize / 4.f) * static_cast<float>(Grid);
		DrawLine(MapX + Offset, MapY, MapX + Offset, MapY + MapSize, FLinearColor(1.f, 1.f, 1.f, 0.05f), 1.f);
		DrawLine(MapX, MapY + Offset, MapX + MapSize, MapY + Offset, FLinearColor(1.f, 1.f, 1.f, 0.05f), 1.f);
	}

	DrawLine(MapX, MapY, MapX + MapSize, MapY, ArenaHudStyle::PanelEdge, 1.f);
	DrawLine(MapX, MapY + MapSize, MapX + MapSize, MapY + MapSize, ArenaHudStyle::PanelEdge, 1.f);
	DrawLine(MapX, MapY, MapX, MapY + MapSize, ArenaHudStyle::PanelEdge, 1.f);
	DrawLine(MapX + MapSize, MapY, MapX + MapSize, MapY + MapSize, ArenaHudStyle::PanelEdge, 1.f);

	// Collectibles
	const float CoreDot = FMath::Max(2.5f, 3.f * S);
	for (TActorIterator<AArenaCollectible> It(World); It; ++It)
	{
		const FVector Location = It->GetActorLocation();
		const float DotX = CenterX + static_cast<float>(Location.Y * Scale);
		const float DotY = CenterY - static_cast<float>(Location.X * Scale);
		DrawRect(FLinearColor(0.1f, 1.f, 0.9f, 0.95f), DotX - CoreDot, DotY - CoreDot, CoreDot * 2.f, CoreDot * 2.f);
	}

	// Hunters
	const float HunterDot = FMath::Max(2.5f, 3.5f * S);
	for (TActorIterator<AArenaHunter> It(World); It; ++It)
	{
		const FVector Location = It->GetActorLocation();
		const float DotX = CenterX + static_cast<float>(Location.Y * Scale);
		const float DotY = CenterY - static_cast<float>(Location.X * Scale);
		DrawRect(FLinearColor(1.f, 0.22f, 0.12f, 0.95f), DotX - HunterDot, DotY - HunterDot, HunterDot * 2.f, HunterDot * 2.f);
	}

	// Player
	const FVector PlayerLocation = Character->GetActorLocation();
	const float PlayerX = CenterX + static_cast<float>(PlayerLocation.Y * Scale);
	const float PlayerY = CenterY - static_cast<float>(PlayerLocation.X * Scale);
	const float ArrowLength = 16.f * S;
	DrawRect(FLinearColor::White, PlayerX - 3.5f * S, PlayerY - 3.5f * S, 7.f * S, 7.f * S);
	DrawLine(
		PlayerX, PlayerY,
		PlayerX + static_cast<float>(Character->GetActorForwardVector().Y) * ArrowLength,
		PlayerY - static_cast<float>(Character->GetActorForwardVector().X) * ArrowLength,
		ArenaHudStyle::Accent, 2.f);

	if (!bMobile)
	{
		UFont* Font = GEngine ? GEngine->GetMediumFont() : nullptr;
		DrawTextShadowed(TEXT("N"), CenterX - 5.f * S, MapY - 20.f * S, ArenaHudStyle::SubText, Font, 0.8f * S);
	}
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

void AArenaHUD::ShowMessage(const FString& Message, FLinearColor Color, float Duration)
{
	if (!GetWorld())
	{
		return;
	}

	FArenaHudMessage Entry;
	Entry.Text = Message;
	Entry.Color = Color;
	Entry.StartTime = GetWorld()->GetTimeSeconds();
	Entry.ExpireTime = Entry.StartTime + FMath::Max(0.25f, Duration);
	Messages.Add(Entry);

	while (Messages.Num() > 4)
	{
		Messages.RemoveAt(0);
	}
}

void AArenaHUD::DrawMessages()
{
	if (!GetWorld())
	{
		return;
	}

	const float Now = GetWorld()->GetTimeSeconds();
	UFont* Font = GEngine ? GEngine->GetLargeFont() : nullptr;
	if (!Font)
	{
		Messages.Reset();
		return;
	}

	for (int32 Index = Messages.Num() - 1; Index >= 0; --Index)
	{
		if (Now >= Messages[Index].ExpireTime)
		{
			Messages.RemoveAt(Index);
		}
	}

	const float S = GetHudScale();
	float Y = Canvas->ClipY * 0.24f;

	for (const FArenaHudMessage& Message : Messages)
	{
		const float Life = Message.ExpireTime - Message.StartTime;
		const float Age = Now - Message.StartTime;
		const float Alpha = FMath::Clamp(1.f - (Age / FMath::Max(0.01f, Life)), 0.f, 1.f);

		float TextW = 0.f;
		float TextH = 0.f;
		GetTextSize(Message.Text, TextW, TextH, Font, 1.35f * S);

		FLinearColor Color = Message.Color;
		Color.A = Alpha;
		DrawTextShadowed(Message.Text, Canvas->ClipX * 0.5f - TextW * 0.5f, Y, Color, Font, 1.35f * S);
		Y += TextH + 8.f * S;
	}
}

// ---------------------------------------------------------------------------
// Crosshair + danger vignette
// ---------------------------------------------------------------------------

void AArenaHUD::DrawCrosshair()
{
	const float CX = Canvas->ClipX * 0.5f;
	const float CY = Canvas->ClipY * 0.5f;
	const FLinearColor Color(1.f, 1.f, 1.f, 0.35f);

	DrawLine(CX - 7.f, CY, CX - 2.f, CY, Color, 1.f);
	DrawLine(CX + 2.f, CY, CX + 7.f, CY, Color, 1.f);
	DrawLine(CX, CY - 7.f, CX, CY - 2.f, Color, 1.f);
	DrawLine(CX, CY + 2.f, CX, CY + 7.f, Color, 1.f);
}

void AArenaHUD::DrawDangerVignette()
{
	UWorld* World = GetWorld();
	const AArenaCharacter* Character = PlayerOwner ? Cast<AArenaCharacter>(PlayerOwner->GetPawn()) : nullptr;
	if (!World || !Character)
	{
		return;
	}

	float Nearest = TNumericLimits<float>::Max();
	int32 HunterCount = 0;

	for (TActorIterator<AArenaHunter> It(World); It; ++It)
	{
		++HunterCount;
		Nearest = FMath::Min(Nearest, FVector::Dist2D(It->GetActorLocation(), Character->GetActorLocation()));
	}

	if (HunterCount == 0 || Nearest > 900.f)
	{
		return;
	}

	const float Danger = FMath::Clamp(1.f - (Nearest / 900.f), 0.f, 1.f);
	const float Alpha = Danger * 0.35f;
	const FLinearColor Edge(0.9f, 0.05f, 0.02f, Alpha);
	const float Thickness = 10.f + Danger * 26.f;

	DrawRect(Edge, 0.f, 0.f, Canvas->ClipX, Thickness);
	DrawRect(Edge, 0.f, Canvas->ClipY - Thickness, Canvas->ClipX, Thickness);
	DrawRect(Edge, 0.f, 0.f, Thickness, Canvas->ClipY);
	DrawRect(Edge, Canvas->ClipX - Thickness, 0.f, Thickness, Canvas->ClipY);
}

// ---------------------------------------------------------------------------
// Touch controls
// ---------------------------------------------------------------------------

void AArenaHUD::DrawMobileControls()
{
	const FVector2D Viewport(Canvas->ClipX, Canvas->ClipY);
	const AArenaPlayerController* PC = Cast<AArenaPlayerController>(PlayerOwner);
	const float S = GetHudScale();

	UFont* Font = GEngine ? GEngine->GetMediumFont() : nullptr;

	// ---- Virtual stick ----------------------------------------------------
	const FVector2D RestCenter = ArenaTouch::GetJoystickRestCenter(Viewport);
	const FVector2D StickCenter = (PC && PC->IsTouchMoveActive()) ? PC->GetTouchMoveOrigin() : RestCenter;
	const FVector2D KnobCenter = (PC && PC->IsTouchMoveActive()) ? PC->GetTouchMoveCurrent() : RestCenter;
	const float StickRadius = ArenaTouch::GetJoystickRadius(Viewport);
	const float KnobRadius = ArenaTouch::GetJoystickKnobRadius(Viewport);

	DrawFilledCircle(StickCenter, StickRadius, ArenaHudStyle::TouchGlass, 40);
	DrawRing(StickCenter, StickRadius, FLinearColor(0.8f, 0.95f, 1.f, 0.45f), 2.f, 40);
	DrawRing(StickCenter, StickRadius * 0.5f, FLinearColor(0.8f, 0.95f, 1.f, 0.16f), 1.f, 32);
	DrawFilledCircle(KnobCenter, KnobRadius, ArenaHudStyle::TouchGlassStrong, 28);
	DrawRing(KnobCenter, KnobRadius, FLinearColor(0.9f, 0.98f, 1.f, 0.7f), 2.f, 28);

	// ---- Jump -------------------------------------------------------------
	const FVector2D JumpCenter = ArenaTouch::GetJumpButtonCenter(Viewport);
	const float ButtonRadius = ArenaTouch::GetButtonRadius(Viewport);

	DrawFilledCircle(JumpCenter, ButtonRadius, FLinearColor(0.10f, 0.55f, 0.95f, 0.30f), 32);
	DrawRing(JumpCenter, ButtonRadius, ArenaHudStyle::Accent, 2.5f, 32);
	DrawCenteredText(TEXT("JUMP"), JumpCenter, ArenaHudStyle::Text, Font, 0.85f * S);

	// ---- Sprint (toggle) --------------------------------------------------
	const FVector2D SprintCenter = ArenaTouch::GetSprintButtonCenter(Viewport);
	const float SprintRadius = ButtonRadius * 0.72f;
	const bool bSprintOn = PC && PC->IsTouchSprintOn();

	DrawFilledCircle(SprintCenter, SprintRadius,
		bSprintOn ? FLinearColor(0.15f, 0.95f, 0.55f, 0.45f) : ArenaHudStyle::TouchGlass, 28);
	DrawRing(SprintCenter, SprintRadius,
		bSprintOn ? FLinearColor(0.3f, 1.f, 0.65f, 0.95f) : FLinearColor(0.8f, 0.95f, 1.f, 0.45f), 2.f, 28);
	DrawCenteredText(TEXT("RUN"), SprintCenter, ArenaHudStyle::Text, Font, 0.7f * S);

	// ---- Hint -------------------------------------------------------------
	DrawTextShadowed(TEXT("drag right side to look"), 36.f * S, Canvas->ClipY * 0.5f, ArenaHudStyle::SubText, Font, 0.7f * S);
}

// ---------------------------------------------------------------------------

void AArenaHUD::DrawTextShadowed(const FString& Text, float X, float Y, const FLinearColor& Color, UFont* Font, float Scale)
{
	if (!Font)
	{
		return;
	}

	const FLinearColor Shadow(0.f, 0.f, 0.f, Color.A * 0.8f);
	DrawText(Text, Shadow, X + 2.f, Y + 2.f, Font, Scale);
	DrawText(Text, Color, X, Y, Font, Scale);
}
