#include "UI/SeagullHUD.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullPlayerController.h"
#include "Core/SeagullTypes.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Button.h"
#include "Components/Border.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/ProgressBar.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Kismet/GameplayStatics.h"

void USeagullHUD::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	// Transparent root: gameplay stays visible behind the HUD elements
	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	// Charcoal backing keeps every HUD label readable over the cream arena.
	UBorder* TopPlate = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::DarkBG, 0.f);
	TopPlate->SetVisibility(ESlateVisibility::HitTestInvisible);
	if (UCanvasPanelSlot* PlateSlot = RootCanvas->AddChildToCanvas(TopPlate))
	{
		PlateSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 0.f));
		PlateSlot->SetOffsets(FMargin(24.f, 14.f, 24.f, 112.f));
	}
	UBorder* BottomPlate = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::DarkBG, 0.f);
	BottomPlate->SetVisibility(ESlateVisibility::HitTestInvisible);
	if (UCanvasPanelSlot* PlateSlot = RootCanvas->AddChildToCanvas(BottomPlate))
	{
		PlateSlot->SetAnchors(FAnchors(0.f, 1.f, 1.f, 1.f));
		PlateSlot->SetOffsets(FMargin(24.f, -130.f, 24.f, 116.f));
	}

	// Top-left: wave + HP bar
	UVerticalBox* TopLeft = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	if (UCanvasPanelSlot* TopLeftSlot = RootCanvas->AddChildToCanvas(TopLeft))
	{
		TopLeftSlot->SetAnchors(FAnchors(0.f, 0.f));
		TopLeftSlot->SetAlignment(FVector2D(0.f, 0.f));
		TopLeftSlot->SetPosition(FVector2D(40.f, 30.f));
		TopLeftSlot->SetAutoSize(true);
	}
	WaveText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Wave 1"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("WaveText"));
	SeagullWidgetStyles::AddRow(TopLeft, WaveText, 4.f);

	USizeBox* HPBarSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
	HPBarSize->SetWidthOverride(320.f);
	HPBarSize->SetHeightOverride(24.f);
	HPBar = SeagullWidgetStyles::MakeBar(WidgetTree, SeagullColors::CrabRed, TEXT("HPBar"));
	HPBarSize->AddChild(HPBar);
	if (UVerticalBoxSlot* HPSlot = TopLeft->AddChildToVerticalBox(HPBarSize))
	{
		HPSlot->SetPadding(FMargin(0.f, 4.f));
		HPSlot->SetHorizontalAlignment(HAlign_Left);
	}

	// Top-center: timer
	TimerText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("3:00"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("TimerText"));
	if (UCanvasPanelSlot* TimerSlot = RootCanvas->AddChildToCanvas(TimerText))
	{
		TimerSlot->SetAnchors(FAnchors(0.5f, 0.f));
		TimerSlot->SetAlignment(FVector2D(0.5f, 0.f));
		TimerSlot->SetPosition(FVector2D(0.f, 30.f));
		TimerSlot->SetAutoSize(true);
	}

	// Top-right: score + level
	UVerticalBox* TopRight = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	if (UCanvasPanelSlot* TopRightSlot = RootCanvas->AddChildToCanvas(TopRight))
	{
		TopRightSlot->SetAnchors(FAnchors(1.f, 0.f));
		TopRightSlot->SetAlignment(FVector2D(1.f, 0.f));
		TopRightSlot->SetPosition(FVector2D(-40.f, 30.f));
		TopRightSlot->SetAutoSize(true);
	}
	ScoreText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Score: 0"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::XPGold, TEXT("ScoreText"));
	ScoreText->SetJustification(ETextJustify::Right);
	SeagullWidgetStyles::AddRow(TopRight, ScoreText, 4.f);
	LevelText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Lv. 1"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("LevelText"));
	LevelText->SetJustification(ETextJustify::Right);
	SeagullWidgetStyles::AddRow(TopRight, LevelText, 4.f);

	RunStatusText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""), 14, SeagullColors::Sand);
	RunStatusText->SetAutoWrapText(true);
	if (UCanvasPanelSlot* StatusSlot = RootCanvas->AddChildToCanvas(RunStatusText))
	{
		StatusSlot->SetAnchors(FAnchors(0.f, 1.f, 1.f, 1.f));
		StatusSlot->SetOffsets(FMargin(40.f, -116.f, 220.f, 50.f));
	}

	// Bottom: XP bar stretched across the screen
	XPBar = SeagullWidgetStyles::MakeBar(WidgetTree, SeagullColors::XPGold, TEXT("XPBar"));
	XPBar->SetPercent(0.f);
	if (UCanvasPanelSlot* XPSlot = RootCanvas->AddChildToCanvas(XPBar))
	{
		XPSlot->SetAnchors(FAnchors(0.f, 1.f, 1.f, 1.f));
		// Left/right inset 40, positioned 54 above the bottom edge, 24 tall
		XPSlot->SetOffsets(FMargin(40.f, -54.f, 40.f, 24.f));
	}

	// Bottom-right: pause button
	PauseButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Pause"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::SmallFontSize, TEXT("PauseButton"));
	if (UCanvasPanelSlot* PauseSlot = RootCanvas->AddChildToCanvas(PauseButton))
	{
		PauseSlot->SetAnchors(FAnchors(1.f, 1.f));
		PauseSlot->SetAlignment(FVector2D(1.f, 1.f));
		PauseSlot->SetPosition(FVector2D(-40.f, -70.f));
		PauseSlot->SetAutoSize(true);
	}
}

void USeagullHUD::NativeConstruct()
{
	Super::NativeConstruct();
	if (PauseButton) PauseButton->OnClicked.AddDynamic(this, &USeagullHUD::OnPauseClicked);
}

void USeagullHUD::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);
	if (ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld())))
	{
		if (RunStatusText) RunStatusText->SetText(FText::FromString(GM->GetRunStatus()));
	}

	ASeagullStormGameState* GS = GetWorld()->GetGameState<ASeagullStormGameState>();
	if (!GS) return;

	if (WaveText)
		WaveText->SetText(FText::FromString(FString::Printf(TEXT("Wave %d"), GS->CurrentWave)));

	if (TimerText)
	{
		int32 Seconds = FMath::Max(0, static_cast<int32>(GS->TimeRemaining));
		TimerText->SetText(FText::FromString(FString::Printf(TEXT("%d:%02d"), Seconds / 60, Seconds % 60)));
	}

	if (ScoreText)
		ScoreText->SetText(FText::FromString(FString::Printf(TEXT("Score: %d"), GS->CurrentScore)));

	if (LevelText)
		LevelText->SetText(FText::FromString(FString::Printf(TEXT("Lv. %d"), GS->CurrentLevel)));

	// HP bar
	ASeagullPlayerPawn* Player = Cast<ASeagullPlayerPawn>(UGameplayStatics::GetPlayerPawn(GetWorld(), 0));
	if (Player && Player->HealthComponent && HPBar)
	{
		float Pct = static_cast<float>(Player->HealthComponent->CurrentHP) /
			FMath::Max(1, Player->HealthComponent->MaxHP);
		HPBar->SetPercent(Pct);
	}

	// XP bar
	if (XPBar && GS->XPToNextLevel > 0)
	{
		float Pct = static_cast<float>(GS->CurrentXP) / static_cast<float>(GS->XPToNextLevel);
		XPBar->SetPercent(Pct);
	}
}

void USeagullHUD::OnPauseClicked()
{
	ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(UGameplayStatics::GetPlayerController(GetWorld(), 0));
	if (PC) PC->TogglePause();
}
