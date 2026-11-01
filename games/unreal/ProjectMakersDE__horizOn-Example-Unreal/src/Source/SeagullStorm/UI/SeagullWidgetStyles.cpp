#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullTypes.h"
#include "Blueprint/WidgetTree.h"
#include "Brushes/SlateColorBrush.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/ButtonSlot.h"
#include "Components/EditableTextBox.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Misc/Paths.h"
#include "Styling/CoreStyle.h"

namespace
{
	FLinearColor TintColor(const FLinearColor& Color, float Factor)
	{
		return FLinearColor(
			FMath::Clamp(Color.R * Factor, 0.f, 1.f),
			FMath::Clamp(Color.G * Factor, 0.f, 1.f),
			FMath::Clamp(Color.B * Factor, 0.f, 1.f),
			Color.A);
	}
}

FSlateFontInfo SeagullWidgetStyles::GetPixelFont(int32 Size)
{
	// Keep the historic helper name and bundled font for compatibility. The
	// engine's Roboto Regular face is more readable for the cel-shaded UI.
	return FCoreStyle::GetDefaultFontStyle(TEXT("Regular"), Size, FFontOutlineSettings());
}

FButtonStyle SeagullWidgetStyles::MakeButtonStyle(const FLinearColor& BaseColor)
{
	FButtonStyle Style;
	Style.SetNormal(FSlateColorBrush(BaseColor));
	Style.SetHovered(FSlateColorBrush(TintColor(BaseColor, 1.2f)));
	Style.SetPressed(FSlateColorBrush(TintColor(BaseColor, 0.8f)));
	Style.SetNormalPadding(FMargin(16.f, 10.f));
	Style.SetPressedPadding(FMargin(16.f, 12.f, 16.f, 8.f));
	return Style;
}

UTextBlock* SeagullWidgetStyles::MakeText(UWidgetTree* Tree, const FString& Text, int32 FontSize,
	const FLinearColor& Color, FName WidgetName)
{
	UTextBlock* Block = Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), WidgetName);
	Block->SetText(FText::FromString(Text));
	Block->SetFont(GetPixelFont(FontSize));
	Block->SetColorAndOpacity(FSlateColor(Color));
	return Block;
}

UButton* SeagullWidgetStyles::MakeTextButton(UWidgetTree* Tree, const FString& Label, const FLinearColor& ButtonColor,
	const FLinearColor& LabelColor, int32 FontSize, FName WidgetName)
{
	UButton* Button = Tree->ConstructWidget<UButton>(UButton::StaticClass(), WidgetName);
	Button->SetStyle(MakeButtonStyle(ButtonColor));

	UTextBlock* LabelText = MakeText(Tree, Label, FontSize, LabelColor);
	LabelText->SetJustification(ETextJustify::Center);
	if (UButtonSlot* LabelSlot = Cast<UButtonSlot>(Button->AddChild(LabelText)))
	{
		LabelSlot->SetHorizontalAlignment(HAlign_Center);
		LabelSlot->SetVerticalAlignment(VAlign_Center);
	}
	return Button;
}

UEditableTextBox* SeagullWidgetStyles::MakeTextInput(UWidgetTree* Tree, const FString& Hint, FName WidgetName)
{
	UEditableTextBox* Box = Tree->ConstructWidget<UEditableTextBox>(UEditableTextBox::StaticClass(), WidgetName);
	Box->SetHintText(FText::FromString(Hint));
	// UEditableTextBox has no font setter in 5.5: set the style before Slate builds it.
	Box->WidgetStyle.SetFont(GetPixelFont(SmallFontSize));
    Box->WidgetStyle.SetForegroundColor(FSlateColor(SeagullColors::LightText));
    Box->WidgetStyle.SetBackgroundImageNormal(FSlateColorBrush(SeagullColors::DarkBG));
    Box->WidgetStyle.SetBackgroundImageHovered(FSlateColorBrush(SeagullColors::PanelBG));
    Box->WidgetStyle.SetBackgroundImageFocused(FSlateColorBrush(SeagullColors::PanelBG));
    Box->WidgetStyle.SetPadding(FMargin(12.f,8.f));
	return Box;
}

UProgressBar* SeagullWidgetStyles::MakeBar(UWidgetTree* Tree, const FLinearColor& FillColor, FName WidgetName)
{
	UProgressBar* Bar = Tree->ConstructWidget<UProgressBar>(UProgressBar::StaticClass(), WidgetName);
	FProgressBarStyle BarStyle;
	BarStyle.SetBackgroundImage(FSlateColorBrush(FLinearColor(0.f, 0.f, 0.f, 0.6f)));
	BarStyle.SetFillImage(FSlateColorBrush(FLinearColor::White));
	Bar->SetWidgetStyle(BarStyle);
	Bar->SetFillColorAndOpacity(FillColor);
	Bar->SetPercent(1.f);
	return Bar;
}

UBorder* SeagullWidgetStyles::MakePanel(UWidgetTree* Tree, const FLinearColor& Color, float Padding)
{
	UBorder* Panel = Tree->ConstructWidget<UBorder>(UBorder::StaticClass());
	Panel->SetBrushColor(Color);
	Panel->SetPadding(FMargin(Padding));
	return Panel;
}

void SeagullWidgetStyles::AddRow(UVerticalBox* Box, UWidget* Child, float PadY)
{
	if (!Box || !Child) return;
	if (UVerticalBoxSlot* RowSlot = Box->AddChildToVerticalBox(Child))
	{
		RowSlot->SetPadding(FMargin(0.f, PadY));
		RowSlot->SetHorizontalAlignment(HAlign_Fill);
	}
}
