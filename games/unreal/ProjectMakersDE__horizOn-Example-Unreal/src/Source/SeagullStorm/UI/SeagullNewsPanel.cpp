#include "UI/SeagullNewsPanel.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/ScrollBox.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullNewsPanel::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	FLinearColor DimColor = SeagullColors::DarkBG;
	DimColor.A = 0.85f;
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
	ColumnSize->SetWidthOverride(820.f);
	ColumnSize->SetHeightOverride(560.f);
	Panel->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("NEWS"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::Orange);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 10.f);

	UScrollBox* NewsScroll = WidgetTree->ConstructWidget<UScrollBox>(UScrollBox::StaticClass());
	NewsList = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass(), TEXT("NewsList"));
	NewsScroll->AddChild(NewsList);
	if (UVerticalBoxSlot* ScrollSlot = Column->AddChildToVerticalBox(NewsScroll))
	{
		ScrollSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		ScrollSlot->SetPadding(FMargin(0.f, 8.f));
	}

	CloseButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Close"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("CloseButton"));
	SeagullWidgetStyles::AddRow(Column, CloseButton, 8.f);
}

void USeagullNewsPanel::NativeConstruct()
{
	Super::NativeConstruct();
	if (CloseButton) CloseButton->OnClicked.AddDynamic(this, &USeagullNewsPanel::OnCloseClicked);
	LoadNews();
}

void USeagullNewsPanel::LoadNews()
{
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (!GI) return;

	// Populate NewsList widget from cache — zero network requests during run
	if (NewsList)
	{
		NewsList->ClearChildren();
		for (const FHorizonNewsEntry& Entry : GI->CachedNews)
		{
			UTextBlock* Row = NewObject<UTextBlock>(this);
			Row->SetText(FText::FromString(
				FString::Printf(TEXT("[%s] %s"), *Entry.ReleaseDate, *Entry.Title)));
			Row->SetFont(SeagullWidgetStyles::GetPixelFont(SeagullWidgetStyles::SmallFontSize));
			Row->SetColorAndOpacity(FSlateColor(SeagullColors::LightText));
			Row->SetAutoWrapText(true);
			NewsList->AddChildToVerticalBox(Row);
		}
	}
	UE_LOG(LogSeagullStorm, Log, TEXT("News panel loaded: %d entries"), GI->CachedNews.Num());
}

void USeagullNewsPanel::OnCloseClicked()
{
	RemoveFromParent();
}
