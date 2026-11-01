#include "UI/SeagullLevelUpOverlay.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullPlayerController.h"
#include "Core/SeagullGameInstance.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Audio/SeagullAudioManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/ButtonSlot.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullLevelUpOverlay::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	// Dim the paused gameplay behind the overlay
	FLinearColor DimColor = SeagullColors::DarkBG;
	DimColor.A = 0.75f;
	UBorder* Dim = SeagullWidgetStyles::MakePanel(WidgetTree, DimColor, 0.f);
	if (UCanvasPanelSlot* DimSlot = RootCanvas->AddChildToCanvas(Dim))
	{
		DimSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 1.f));
		DimSlot->SetOffsets(FMargin(0.f));
	}

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	if (UCanvasPanelSlot* ColumnSlot = RootCanvas->AddChildToCanvas(Column))
	{
		ColumnSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		ColumnSlot->SetAlignment(FVector2D(0.5f, 0.5f));
		ColumnSlot->SetAutoSize(true);
	}

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("LEVEL UP!"),
		SeagullWidgetStyles::TitleFontSize, SeagullColors::XPGold);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 16.f);

	// Three choice cards side by side
	UHorizontalBox* CardRow = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass());
	SeagullWidgetStyles::AddRow(Column, CardRow, 8.f);

	UButton** ChoiceButtons[] = { &Choice1Button, &Choice2Button, &Choice3Button };
	UTextBlock** ChoiceTexts[] = { &Choice1Text, &Choice2Text, &Choice3Text };
	for (int32 i = 0; i < 3; i++)
	{
		USizeBox* CardSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
		CardSize->SetWidthOverride(300.f);
		CardSize->SetHeightOverride(220.f);

		UButton* CardButton = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(),
			FName(*FString::Printf(TEXT("Choice%dButton"), i + 1)));
		CardButton->SetStyle(SeagullWidgetStyles::MakeButtonStyle(SeagullColors::PanelBG));
		CardSize->AddChild(CardButton);

		UTextBlock* CardText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""),
			SeagullWidgetStyles::SmallFontSize, SeagullColors::LightText,
			FName(*FString::Printf(TEXT("Choice%dText"), i + 1)));
		CardText->SetJustification(ETextJustify::Center);
		CardText->SetAutoWrapText(true);
		if (UButtonSlot* CardTextSlot = Cast<UButtonSlot>(CardButton->AddChild(CardText)))
		{
			CardTextSlot->SetHorizontalAlignment(HAlign_Fill);
			CardTextSlot->SetVerticalAlignment(VAlign_Center);
			CardTextSlot->SetPadding(FMargin(12.f));
		}

		if (UHorizontalBoxSlot* CardSlot = CardRow->AddChildToHorizontalBox(CardSize))
		{
			CardSlot->SetPadding(FMargin(10.f, 0.f));
		}

		*ChoiceButtons[i] = CardButton;
		*ChoiceTexts[i] = CardText;
	}

	// Bind here (runs once per instance), NOT in NativeConstruct: the controller
	// reuses this widget across level-ups, and NativeConstruct re-runs on every
	// AddToViewport, which would stack duplicate OnClicked bindings.
	if (Choice1Button) Choice1Button->OnClicked.AddDynamic(this, &USeagullLevelUpOverlay::OnChoice1);
	if (Choice2Button) Choice2Button->OnClicked.AddDynamic(this, &USeagullLevelUpOverlay::OnChoice2);
	if (Choice3Button) Choice3Button->OnClicked.AddDynamic(this, &USeagullLevelUpOverlay::OnChoice3);
}

void USeagullLevelUpOverlay::SetChoices(const TArray<FSeagullLevelUpChoice>& InChoices)
{
	Choices = InChoices;

	UButton* Buttons[] = { Choice1Button, Choice2Button, Choice3Button };
	UTextBlock* Texts[] = { Choice1Text, Choice2Text, Choice3Text };
	for (int32 i = 0; i < 3; i++)
	{
		if (Buttons[i]) Buttons[i]->SetVisibility(Choices.IsValidIndex(i) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed);
		if (Texts[i] && Choices.IsValidIndex(i))
		{
			Texts[i]->SetText(FText::FromString(
				FString::Printf(TEXT("%s\n%s"), *Choices[i].DisplayName, *Choices[i].Description)));
		}
	}
}

void USeagullLevelUpOverlay::OnChoice1() { SelectChoice(0); }
void USeagullLevelUpOverlay::OnChoice2() { SelectChoice(1); }
void USeagullLevelUpOverlay::OnChoice3() { SelectChoice(2); }

void USeagullLevelUpOverlay::SelectChoice(int32 Index)
{
	if (!Choices.IsValidIndex(Index)) return;

	const FSeagullLevelUpChoice& Choice = Choices[Index];

	// Play upgrade select SFX
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
	if (GM && GM->AudioManager && GM->AudioManager->SFX_UpgradeSelect)
	{
		GM->AudioManager->PlaySFX(GM->AudioManager->SFX_UpgradeSelect, GetWorld());
	}

	// Validated Actions: the pick is part of the run's input log
	if (GM) GM->RecordLevelUpChoice(Index);

	// Apply to game state
	ASeagullStormGameState* GS = GetWorld()->GetGameState<ASeagullStormGameState>();
	if (GS)
	{
		GS->ApplyLevelUpChoice(Choice);
	}

	// Record breadcrumb
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (GI)
	{
		USeagullHorizonManager* HM = GI->GetHorizonManager();
		if (HM)
		{
			HM->RecordBreadcrumb(TEXT("user_action"), FString::Printf(TEXT("chose_%s"), *Choice.Id));
			if (GS) HM->SetCrashCustomKey(TEXT("level"), FString::FromInt(GS->CurrentLevel));
		}
	}

	UE_LOG(LogSeagullStorm, Log, TEXT("Level-up choice: %s"), *Choice.Id);

	// Hide overlay and resume
	ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(UGameplayStatics::GetPlayerController(GetWorld(), 0));
	if (PC) PC->HideLevelUpOverlay();
	if (GS) GS->ResolveLevelUpChoice();
}
