#pragma once

#include "CoreMinimal.h"
#include "Styling/SlateTypes.h"

class UBorder;
class UButton;
class UEditableTextBox;
class UProgressBar;
class UTextBlock;
class UVerticalBox;
class UWidget;
class UWidgetTree;

// Shared styling helpers for the pure-C++ UMG widget trees.
// Three ad-hoc size tiers chosen for 1080p readability. Note that these are
// Slate font sizes (points, ~4/3 px each), and the small tier deliberately
// deviates from a strict 3x scale of the design guide's 16 px / 8 px tiers at
// 480x270: 8 px * 3 would make body rows overpower the layout.
namespace SeagullWidgetStyles
{
	constexpr int32 TitleFontSize = 36;
	constexpr int32 TextFontSize = 20;
	constexpr int32 SmallFontSize = 16;

	// Default engine Regular font; bundled Press Start 2P remains a fallback.
	FSlateFontInfo GetPixelFont(int32 Size);

	// Flat-color button style with hover/pressed tints and padded content.
	FButtonStyle MakeButtonStyle(const FLinearColor& BaseColor);

	UTextBlock* MakeText(UWidgetTree* Tree, const FString& Text, int32 FontSize,
		const FLinearColor& Color, FName WidgetName = NAME_None);

	// Button with a centered single-line label.
	UButton* MakeTextButton(UWidgetTree* Tree, const FString& Label, const FLinearColor& ButtonColor,
		const FLinearColor& LabelColor, int32 FontSize = TextFontSize, FName WidgetName = NAME_None);

	UEditableTextBox* MakeTextInput(UWidgetTree* Tree, const FString& Hint, FName WidgetName = NAME_None);

	UProgressBar* MakeBar(UWidgetTree* Tree, const FLinearColor& FillColor, FName WidgetName = NAME_None);

	// Solid-color padded panel.
	UBorder* MakePanel(UWidgetTree* Tree, const FLinearColor& Color, float Padding = 24.f);

	// Adds Child to Box as a horizontally-filled row with vertical padding.
	void AddRow(UVerticalBox* Box, UWidget* Child, float PadY = 8.f);
}
