#include "Game/CoinRunHUD.h"

#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Game/CoinRunDirector.h"
#include "Kismet/GameplayStatics.h"
#include "Rules/RunState.h"
#include "Rules/Tuning.h"

void ACoinRunHUD::DrawCentered(const FString& Text, float Y, const FLinearColor& Color, float Scale)
{
	UFont* Font = GEngine->GetMediumFont();
	float Width = 0.0f;
	float Height = 0.0f;
	GetTextSize(Text, Width, Height, Font, Scale);
	DrawText(Text, Color, (Canvas->SizeX - Width) * 0.5f, Y, Font, Scale);
}

void ACoinRunHUD::DrawHUD()
{
	Super::DrawHUD();

	if (Canvas == nullptr)
	{
		return;
	}
	const ACoinRunDirector* Director = Cast<ACoinRunDirector>(UGameplayStatics::GetActorOfClass(GetWorld(), ACoinRunDirector::StaticClass()));
	if (Director == nullptr)
	{
		return;
	}

	const coinrun::RunState& State = Director->GetRunState();
	UFont* Font = GEngine->GetMediumFont();
	const float Margin = 24.0f;
	const float Line = 34.0f;
	const float Scale = 1.4f;

	DrawText(FString::Printf(TEXT("Score %d    Wave %d    Best %d"), State.Score(), State.Wave(), FMath::Max(Director->GetBestScore(), State.Score())),
		FLinearColor::White, Margin, Margin, Font, Scale);
	DrawText(FString::Printf(TEXT("Health %d    Time %.1f"), State.Health(), State.TimeLeft()),
		State.TimeLeft() < 10.0f ? FLinearColor(1.0f, 0.4f, 0.4f) : FLinearColor::White, Margin, Margin + Line, Font, Scale);

	if (State.Combo() >= 2)
	{
		DrawText(FString::Printf(TEXT("Combo x%d  (%d in a row)"), State.Multiplier(), State.Combo()),
			FLinearColor(1.0f, 0.85f, 0.2f), Margin, Margin + Line * 2.0f, Font, Scale);
	}

	const float Cooldown = Director->GetDash().CooldownLeft();
	DrawText(Cooldown > 0.0f ? FString::Printf(TEXT("Dash %.1fs"), Cooldown) : FString(TEXT("Dash ready")),
		Cooldown > 0.0f ? FLinearColor(0.7f, 0.7f, 0.7f) : FLinearColor(0.4f, 1.0f, 0.6f), Margin, Margin + Line * 3.0f, Font, Scale);

	const float CentreY = Canvas->SizeY * 0.35f;
	if (State.IsOver())
	{
		const bool bTimeUp = State.Reason() == coinrun::EndReason::TimeUp;
		DrawCentered(bTimeUp ? TEXT("TIME UP") : TEXT("CAUGHT"), CentreY, FLinearColor(1.0f, 0.4f, 0.4f), 3.0f);
		DrawCentered(FString::Printf(TEXT("Score %d%s"), State.Score(), Director->IsNewBest() ? TEXT("   NEW BEST!") : TEXT("")), CentreY + 90.0f, FLinearColor::White, 1.6f);
		DrawCentered(TEXT("Press R or Space to play again"), CentreY + 140.0f, FLinearColor::White, 1.3f);
	}
	else if (Director->IsPaused())
	{
		DrawCentered(TEXT("PAUSED"), CentreY, FLinearColor::White, 3.0f);
		DrawCentered(TEXT("Press P to resume"), CentreY + 90.0f, FLinearColor::White, 1.3f);
	}
	else if (Director->GetRunTime() < 8.0f)
	{
		DrawCentered(TEXT("WASD / arrows to move, Space to dash. Grab gold coins, avoid red drifters. P to pause."),
			Canvas->SizeY * 0.9f, FLinearColor(1.0f, 1.0f, 1.0f, 0.85f), 1.2f);
	}
}
