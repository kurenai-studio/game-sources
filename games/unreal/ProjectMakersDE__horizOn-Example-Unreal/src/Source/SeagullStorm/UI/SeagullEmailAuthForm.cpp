#include "UI/SeagullEmailAuthForm.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/EditableTextBox.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullEmailAuthForm::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	// Dim the screen behind the form (also blocks clicks on widgets below)
	FLinearColor DimColor = SeagullColors::DarkBG;
	DimColor.A = 0.85f;
	UBorder* Dim = SeagullWidgetStyles::MakePanel(WidgetTree, DimColor, 0.f);
	if (UCanvasPanelSlot* DimSlot = RootCanvas->AddChildToCanvas(Dim))
	{
		DimSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 1.f));
		DimSlot->SetOffsets(FMargin(0.f));
	}

	// Centered panel
	UBorder* Panel = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::PanelBG, 32.f);
	if (UCanvasPanelSlot* PanelSlot = RootCanvas->AddChildToCanvas(Panel))
	{
		PanelSlot->SetAnchors(FAnchors(0.5f, 0.5f));
		PanelSlot->SetAlignment(FVector2D(0.5f, 0.5f));
		PanelSlot->SetAutoSize(true);
	}

	USizeBox* ColumnSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
	ColumnSize->SetWidthOverride(680.f);
	Panel->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	TitleLabel = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Sign In"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::Orange, TEXT("TitleLabel"));
	TitleLabel->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, TitleLabel, 10.f);

	EmailInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Email"), TEXT("EmailInput"));
	SeagullWidgetStyles::AddRow(Column, EmailInput);

	PasswordInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Password"), TEXT("PasswordInput"));
	PasswordInput->SetIsPassword(true);
	SeagullWidgetStyles::AddRow(Column, PasswordInput);

	UsernameInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Username"), TEXT("UsernameInput"));
	SeagullWidgetStyles::AddRow(Column, UsernameInput);

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

void USeagullEmailAuthForm::NativeConstruct()
{
	Super::NativeConstruct();

	if (SubmitButton) SubmitButton->OnClicked.AddDynamic(this, &USeagullEmailAuthForm::OnSubmitClicked);
	if (CloseButton) CloseButton->OnClicked.AddDynamic(this, &USeagullEmailAuthForm::OnCloseClicked);

	if (TitleLabel)
	{
		TitleLabel->SetText(FText::FromString(bRegisterMode ? TEXT("Create Account") : TEXT("Sign In")));
	}

	// Hide username field for sign-in mode
	if (UsernameInput && !bRegisterMode)
	{
		UsernameInput->SetVisibility(ESlateVisibility::Collapsed);
	}
}

void USeagullEmailAuthForm::OnSubmitClicked()
{
	FString Email = EmailInput ? EmailInput->GetText().ToString() : TEXT("");
	FString Password = PasswordInput ? PasswordInput->GetText().ToString() : TEXT("");

	if (Email.IsEmpty() || Password.IsEmpty())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Fill in all fields")));
		return;
	}

	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (!GI) return;

	USeagullHorizonManager* HM = GI->GetHorizonManager();
	if (!HM) return;
	if (HM->IsAuthenticating())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Authentication is already in progress. Retry when it finishes.")));
		return;
	}

	if (StatusText) StatusText->SetText(FText::FromString(TEXT("Authenticating...")));

	// Weak self: the form can be closed and GC'd while the request is in flight.
	TWeakObjectPtr<USeagullEmailAuthForm> WeakThis(this);
	if (bRegisterMode)
	{
		FString Username = UsernameInput ? UsernameInput->GetText().ToString() : TEXT("Player");
		// The username field is always built, so the ternary above never yields the
		// fallback; guard the empty-string case too (mirrors the guest flow).
		if (Username.IsEmpty()) Username = TEXT("Player");
		HM->SignUpEmail(Email, Password, Username, [WeakThis](bool bSuccess)
		{
			if (USeagullEmailAuthForm* Form = WeakThis.Get()) Form->OnAuthResult(bSuccess);
		});
	}
	else
	{
		HM->SignInEmail(Email, Password, [WeakThis](bool bSuccess)
		{
			if (USeagullEmailAuthForm* Form = WeakThis.Get()) Form->OnAuthResult(bSuccess);
		});
	}
}

void USeagullEmailAuthForm::OnCloseClicked()
{
	RemoveFromParent();
}

void USeagullEmailAuthForm::OnAuthResult(bool bSuccess)
{
	if (!IsInViewport()) return;
	if (bSuccess)
	{
		RemoveFromParent();
		ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
		if (GM)
		{
			if (USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()))) GI->BeginOnlineSession(bRegisterMode);
			GM->SwitchToScreen(ESeagullGameScreen::Hub);
		}
	}
	else
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Authentication failed")));
	}
}
