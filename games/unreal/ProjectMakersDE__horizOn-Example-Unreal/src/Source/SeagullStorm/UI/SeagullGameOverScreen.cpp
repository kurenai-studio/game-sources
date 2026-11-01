#include "UI/SeagullGameOverScreen.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullGameOverScreen::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	UBorder* Background = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::DarkBG, 0.f);
	if (UCanvasPanelSlot* BackgroundSlot = RootCanvas->AddChildToCanvas(Background))
	{
		BackgroundSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 1.f));
		BackgroundSlot->SetOffsets(FMargin(0.f));
	}

	UBorder* Panel = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::PanelBG, 40.f);
	if (UCanvasPanelSlot* PanelSlot = RootCanvas->AddChildToCanvas(Panel))
	{
		PanelSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		PanelSlot->SetAlignment(FVector2D(0.5f, 0.5f));
		PanelSlot->SetAutoSize(true);
	}

	USizeBox* ColumnSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
	ColumnSize->SetWidthOverride(760.f);
	Panel->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("GAME OVER"),
		SeagullWidgetStyles::TitleFontSize, SeagullColors::Orange);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 12.f);

	ScoreText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Score: 0"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("ScoreText"));
	SeagullWidgetStyles::AddRow(Column, ScoreText, 4.f);

	WavesText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Waves: 0"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("WavesText"));
	SeagullWidgetStyles::AddRow(Column, WavesText, 4.f);

	LevelText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Level: 0"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("LevelText"));
	SeagullWidgetStyles::AddRow(Column, LevelText, 4.f);

	CoinsText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Coins: +0"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::XPGold, TEXT("CoinsText"));
	SeagullWidgetStyles::AddRow(Column, CoinsText, 4.f);

	RankText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Rank: -"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("RankText"));
	SeagullWidgetStyles::AddRow(Column, RankText, 4.f);

	BestText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Best: 0"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::LightText, TEXT("BestText"));
	SeagullWidgetStyles::AddRow(Column, BestText, 4.f);

	// Filled after the submit (Validated Actions result or rejection reason)
	ScoreStatusText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""),
		SeagullWidgetStyles::SmallFontSize, SeagullColors::LightText, TEXT("ScoreStatusText"));
	ScoreStatusText->SetAutoWrapText(true);
	SeagullWidgetStyles::AddRow(Column, ScoreStatusText, 4.f);

	UHorizontalBox* ButtonRow = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass());
	PlayAgainButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Play Again"),
		SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("PlayAgainButton"));
	if (UHorizontalBoxSlot* PlayAgainSlot = ButtonRow->AddChildToHorizontalBox(PlayAgainButton))
	{
		PlayAgainSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		PlayAgainSlot->SetPadding(FMargin(0.f, 0.f, 8.f, 0.f));
	}
	HubButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Hub"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("HubButton"));
	if (UHorizontalBoxSlot* HubSlot = ButtonRow->AddChildToHorizontalBox(HubButton))
	{
		HubSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		HubSlot->SetPadding(FMargin(8.f, 0.f, 0.f, 0.f));
	}
	SeagullWidgetStyles::AddRow(Column, ButtonRow, 16.f);
}

void USeagullGameOverScreen::NativeConstruct()
{
	Super::NativeConstruct();

	if (PlayAgainButton) PlayAgainButton->OnClicked.AddDynamic(this, &USeagullGameOverScreen::OnPlayAgainClicked);
	if (HubButton) HubButton->OnClicked.AddDynamic(this, &USeagullGameOverScreen::OnHubClicked);

	LoadGameOverData();
}

void USeagullGameOverScreen::LoadGameOverData()
{
	ASeagullStormGameState* GS = GetWorld()->GetGameState<ASeagullStormGameState>();
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));

	if (GS)
	{
		if (ScoreText) ScoreText->SetText(FText::FromString(FString::Printf(TEXT("Score: %d"), GS->CurrentScore)));
		if (WavesText) WavesText->SetText(FText::FromString(FString::Printf(TEXT("Waves: %d"), GS->CurrentWave)));
		if (LevelText) LevelText->SetText(FText::FromString(FString::Printf(TEXT("Level: %d"), GS->CurrentLevel)));
		if (CoinsText) CoinsText->SetText(FText::FromString(FString::Printf(TEXT("Coins: +%d"), GS->RunStats.CoinsEarned)));
	}

	if (GI)
	{
		if (BestText) BestText->SetText(FText::FromString(FString::Printf(TEXT("Best: %d"), GI->SaveData.Highscore)));
	}

	// Rank and score status are set externally by GameMode after the submit completes
	if (RankText) RankText->SetText(FText::FromString(TEXT("Rank: -")));
	if (ScoreStatusText) ScoreStatusText->SetText(FText::GetEmpty());
}

void USeagullGameOverScreen::SetScoreStatus(const FString& Message, bool bIsError)
{
	if (!ScoreStatusText) return;

	ScoreStatusText->SetText(FText::FromString(Message));
	ScoreStatusText->SetColorAndOpacity(FSlateColor(bIsError ? SeagullColors::CrabRed : SeagullColors::XPGold));

	// A refused score has no rank
	if (bIsError && RankText)
	{
		RankText->SetText(FText::FromString(TEXT("Rank: -")));
	}
}

void USeagullGameOverScreen::SetRank(int32 Rank)
{
	if (RankText)
	{
		RankText->SetText(FText::FromString(Rank > 0 ? FString::Printf(TEXT("Rank: #%d"), Rank) : FString(TEXT("Rank: -"))));
	}

	// Update Best text to include rank
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (BestText && GI)
	{
		BestText->SetText(FText::FromString(FString::Printf(TEXT("Best: %d (#%d)"), GI->SaveData.Highscore, Rank)));
	}
}

void USeagullGameOverScreen::OnPlayAgainClicked()
{
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
	if (GM) GM->StartRun();
}

void USeagullGameOverScreen::OnHubClicked()
{
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
	if (GM) GM->ReturnToHub();
}
