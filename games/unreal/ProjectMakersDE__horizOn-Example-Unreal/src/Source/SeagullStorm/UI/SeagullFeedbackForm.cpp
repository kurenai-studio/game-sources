#include "UI/SeagullFeedbackForm.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/ComboBoxString.h"
#include "Components/EditableTextBox.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullFeedbackForm::NativeOnInitialized()
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
	ColumnSize->SetWidthOverride(700.f);
	Panel->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("FEEDBACK"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::Orange);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 10.f);

	TitleInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Title"), TEXT("TitleInput"));
	SeagullWidgetStyles::AddRow(Column, TitleInput);

	MessageInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Message"), TEXT("MessageInput"));
	SeagullWidgetStyles::AddRow(Column, MessageInput);

	CategoryDropdown = WidgetTree->ConstructWidget<UComboBoxString>(UComboBoxString::StaticClass(), TEXT("CategoryDropdown"));
	SeagullWidgetStyles::AddRow(Column, CategoryDropdown);

	StatusText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""),
		SeagullWidgetStyles::SmallFontSize, SeagullColors::Orange, TEXT("StatusText"));
	StatusText->SetJustification(ETextJustify::Center);
	StatusText->SetAutoWrapText(true);
	SeagullWidgetStyles::AddRow(Column, StatusText, 6.f);

	UHorizontalBox* ButtonRow = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass());
	SubmitButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Submit"),
		SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("SubmitButton"));
	if (UHorizontalBoxSlot* SubmitSlot = ButtonRow->AddChildToHorizontalBox(SubmitButton))
	{
		SubmitSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		SubmitSlot->SetPadding(FMargin(0.f, 0.f, 8.f, 0.f));
	}
	CloseButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Close"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("CloseButton"));
	if (UHorizontalBoxSlot* CloseSlot = ButtonRow->AddChildToHorizontalBox(CloseButton))
	{
		CloseSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		CloseSlot->SetPadding(FMargin(8.f, 0.f, 0.f, 0.f));
	}
	SeagullWidgetStyles::AddRow(Column, ButtonRow, 10.f);
}

void USeagullFeedbackForm::NativeConstruct()
{
	Super::NativeConstruct();

	if (SubmitButton) SubmitButton->OnClicked.AddDynamic(this, &USeagullFeedbackForm::OnSubmitClicked);
	if (CloseButton) CloseButton->OnClicked.AddDynamic(this, &USeagullFeedbackForm::OnCloseClicked);

	if (CategoryDropdown)
	{
		CategoryDropdown->AddOption(TEXT("BUG"));
		CategoryDropdown->AddOption(TEXT("FEATURE_REQUEST"));
		CategoryDropdown->AddOption(TEXT("GENERAL"));
		CategoryDropdown->SetSelectedOption(TEXT("GENERAL"));
	}
}

void USeagullFeedbackForm::OnSubmitClicked()
{
	FString Title = TitleInput ? TitleInput->GetText().ToString() : TEXT("");
	FString Message = MessageInput ? MessageInput->GetText().ToString() : TEXT("");
	FString Category = CategoryDropdown ? CategoryDropdown->GetSelectedOption() : TEXT("GENERAL");

	if (Title.IsEmpty() || Message.IsEmpty())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Please fill in both fields")));
		return;
	}

	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (!GI) return;

	USeagullHorizonManager* HM = GI->GetHorizonManager();
	if (!HM) return;

	if (StatusText) StatusText->SetText(FText::FromString(TEXT("Submitting...")));

	// Weak self: the form can be closed and GC'd while the request is in flight.
	TWeakObjectPtr<USeagullFeedbackForm> WeakThis(this);
	HM->SubmitFeedback(Title, Message, Category, [WeakThis](bool bSuccess)
	{
		USeagullFeedbackForm* Form = WeakThis.Get();
		if (Form && Form->StatusText)
		{
			Form->StatusText->SetText(FText::FromString(bSuccess ? TEXT("Thank you!") : TEXT("Failed to submit")));
		}
	});
}

void USeagullFeedbackForm::OnCloseClicked()
{
	RemoveFromParent();
}
