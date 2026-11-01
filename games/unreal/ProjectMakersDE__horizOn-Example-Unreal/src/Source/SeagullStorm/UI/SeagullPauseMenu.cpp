#include "UI/SeagullPauseMenu.h"
#include "UI/SeagullNewsPanel.h"
#include "UI/SeagullFeedbackForm.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullPlayerController.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullTypes.h"
#include "Core/SeagullGameInstance.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullPauseMenu::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	// Dim the paused gameplay behind the menu
	FLinearColor DimColor = SeagullColors::DarkBG;
	DimColor.A = 0.75f;
	UBorder* Dim = SeagullWidgetStyles::MakePanel(WidgetTree, DimColor, 0.f);
	if (UCanvasPanelSlot* DimSlot = RootCanvas->AddChildToCanvas(Dim))
	{
		DimSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 1.f));
		DimSlot->SetOffsets(FMargin(0.f));
	}

	UBorder* Panel = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::PanelBG, 32.f);
	if (UCanvasPanelSlot* PanelSlot = RootCanvas->AddChildToCanvas(Panel))
	{
		PanelSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		PanelSlot->SetAlignment(FVector2D(0.5f, 0.5f));
		PanelSlot->SetAutoSize(true);
	}

	USizeBox* ColumnSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
	ColumnSize->SetWidthOverride(520.f);
	Panel->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("PAUSED"),
		SeagullWidgetStyles::TitleFontSize, SeagullColors::Orange);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 12.f);

	ResumeButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Resume"),
		SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("ResumeButton"));
	SeagullWidgetStyles::AddRow(Column, ResumeButton);

	NewsButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("News"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("NewsButton"));
	SeagullWidgetStyles::AddRow(Column, NewsButton);

	FeedbackButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Feedback"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("FeedbackButton"));
	SeagullWidgetStyles::AddRow(Column, FeedbackButton);

	QuitButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Quit Run"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("QuitButton"));
	SeagullWidgetStyles::AddRow(Column, QuitButton);
}

void USeagullPauseMenu::NativeConstruct()
{
	Super::NativeConstruct();

	if (ResumeButton) ResumeButton->OnClicked.AddDynamic(this, &USeagullPauseMenu::OnResumeClicked);
	if (NewsButton) NewsButton->OnClicked.AddDynamic(this, &USeagullPauseMenu::OnNewsClicked);
	if (FeedbackButton) FeedbackButton->OnClicked.AddDynamic(this, &USeagullPauseMenu::OnFeedbackClicked);
	if (QuitButton) QuitButton->OnClicked.AddDynamic(this, &USeagullPauseMenu::OnQuitClicked);
}

void USeagullPauseMenu::OnResumeClicked()
{
	ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(UGameplayStatics::GetPlayerController(GetWorld(), 0));
	if (PC) PC->TogglePause();
}

void USeagullPauseMenu::OnNewsClicked()
{
	APlayerController* PC = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	if (!PC) return;

	USeagullNewsPanel* Panel = CreateWidget<USeagullNewsPanel>(PC);
	if (Panel) Panel->AddToViewport(200);
}

void USeagullPauseMenu::OnFeedbackClicked()
{
	if (const USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()))) { if (GI->bPracticeMode) return; }
	APlayerController* PC = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	if (!PC) return;

	USeagullFeedbackForm* Form = CreateWidget<USeagullFeedbackForm>(PC);
	if (Form) Form->AddToViewport(200);
}

void USeagullPauseMenu::OnQuitClicked()
{
	// Voluntary quit — does not count as a death
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
	if (GM)
	{
		ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(UGameplayStatics::GetPlayerController(GetWorld(), 0));
		if (PC)
		{
			PC->SetPause(false);
		}
		GM->EndRun(false);
	}
}
