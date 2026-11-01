#include "UI/SeagullSettingsPanel.h"
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
#include "Components/SizeBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullSettingsPanel::NativeOnInitialized()
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
	ColumnSize->SetWidthOverride(620.f);
	Panel->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("SETTINGS"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::Orange);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 10.f);

	UserInfoText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""),
		SeagullWidgetStyles::SmallFontSize, SeagullColors::LightText, TEXT("UserInfoText"));
	UserInfoText->SetJustification(ETextJustify::Center);
	UserInfoText->SetAutoWrapText(true);
	SeagullWidgetStyles::AddRow(Column, UserInfoText, 6.f);

	SignOutButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Sign Out"),
		SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("SignOutButton"));
	SeagullWidgetStyles::AddRow(Column, SignOutButton);

	CloseButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Close"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("CloseButton"));
	SeagullWidgetStyles::AddRow(Column, CloseButton);
}

void USeagullSettingsPanel::NativeConstruct()
{
	Super::NativeConstruct();

	if (SignOutButton) SignOutButton->OnClicked.AddDynamic(this, &USeagullSettingsPanel::OnSignOutClicked);
	if (CloseButton) CloseButton->OnClicked.AddDynamic(this, &USeagullSettingsPanel::OnCloseClicked);

	// Display user info
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (GI && UserInfoText)
	{
		USeagullHorizonManager* HM = GI->GetHorizonManager();
		if (HM)
		{
			UserInfoText->SetText(FText::FromString(
				GI->bPracticeMode ? FString(TEXT("Offline practice / local progress")) : FString::Printf(TEXT("Signed in as: %s"), *HM->GetDisplayName())));
		}
	}
}

void USeagullSettingsPanel::OnSignOutClicked()
{
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (GI)
	{
		USeagullHorizonManager* HM = GI->GetHorizonManager();
		if (HM)
		{
			HM->SignOut();
			GI->bPracticeMode = false;
			GI->bCloudSaveReady = false;
			GI->SaveOwnerId.Empty();
			GI->bSaveLoaded = false;
			GI->bConfigLoaded = false;
			GI->bNewsLoaded = false;
			GI->CachedNews.Empty();
			GI->SaveData.InitDefaults();

			// Close the modal before switching so it cannot sit on top of the
			// title screen (mirrors OnCloseClicked).
			RemoveFromParent();

			ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
			if (GM)
			{
				GM->SwitchToScreen(ESeagullGameScreen::Title);
			}
		}
	}
}

void USeagullSettingsPanel::OnCloseClicked()
{
	RemoveFromParent();
}
