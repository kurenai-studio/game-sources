#include "UI/SeagullGiftCodePanel.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullPlayerController.h"
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
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Dom/JsonObject.h"
#include "SeagullStorm.h"

void USeagullGiftCodePanel::NativeOnInitialized()
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

	UTextBlock* Heading = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("GIFT CODE"),
		SeagullWidgetStyles::TextFontSize, SeagullColors::Orange);
	Heading->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Heading, 10.f);

	CodeInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Enter your code..."), TEXT("CodeInput"));
	SeagullWidgetStyles::AddRow(Column, CodeInput);

	StatusText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""),
		SeagullWidgetStyles::SmallFontSize, SeagullColors::Orange, TEXT("StatusText"));
	StatusText->SetJustification(ETextJustify::Center);
	StatusText->SetAutoWrapText(true);
	SeagullWidgetStyles::AddRow(Column, StatusText, 6.f);

	UHorizontalBox* ButtonRow = WidgetTree->ConstructWidget<UHorizontalBox>(UHorizontalBox::StaticClass());
	RedeemButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Redeem"),
		SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("RedeemButton"));
	if (UHorizontalBoxSlot* RedeemSlot = ButtonRow->AddChildToHorizontalBox(RedeemButton))
	{
		RedeemSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
		RedeemSlot->SetPadding(FMargin(0.f, 0.f, 8.f, 0.f));
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

void USeagullGiftCodePanel::NativeConstruct()
{
	Super::NativeConstruct();

	if (RedeemButton) RedeemButton->OnClicked.AddDynamic(this, &USeagullGiftCodePanel::OnRedeemClicked);
	if (CloseButton) CloseButton->OnClicked.AddDynamic(this, &USeagullGiftCodePanel::OnCloseClicked);
}

void USeagullGiftCodePanel::OnRedeemClicked()
{
	if (bRedeeming) return;
	FString Code = CodeInput ? CodeInput->GetText().ToString().TrimStartAndEnd() : TEXT("");
	if (Code.IsEmpty())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Enter a code")));
		return;
	}

	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (!GI) return;
	USeagullHorizonManager* HM = GI->GetHorizonManager();
	if (!HM || GI->bPracticeMode || !GI->CanMutateProgress())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Sign in and wait for a successful initial cloud save load before redeeming.")));
		return;
	}

	// Check if already redeemed
	if (GI->SaveData.GiftCodesRedeemed.Contains(Code))
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Already redeemed")));
		return;
	}

	bRedeeming = true;
	if (RedeemButton) RedeemButton->SetIsEnabled(false);
	if (StatusText) StatusText->SetText(FText::FromString(TEXT("Validating...")));

	// A validated code and its rewards belong to this exact player session.
	const uint64 Generation = GI->SessionGeneration;
	const FString Owner = GI->SaveOwnerId;
	TWeakObjectPtr<USeagullGiftCodePanel> WeakThis(this);
	TWeakObjectPtr<USeagullGameInstance> WeakGI(GI);
	TWeakObjectPtr<USeagullHorizonManager> WeakHM(HM);
	HM->ValidateGiftCode(Code, [WeakThis, WeakGI, WeakHM, Code, Generation, Owner](bool bRequestSuccess, bool bValid)
	{
		USeagullGiftCodePanel* Panel = WeakThis.Get();
		USeagullGameInstance* Instance = WeakGI.Get();
		USeagullHorizonManager* Manager = WeakHM.Get();
		if (!Panel || !Panel->IsInViewport() || !Instance || !Manager) return;
		if (Instance->SessionGeneration != Generation || Instance->SaveOwnerId != Owner || Instance->bPracticeMode
			|| Manager->GetUserId() != Owner || !Instance->CanMutateProgress())
		{
			Panel->CompleteRequest(TEXT("Player session changed; code was not redeemed."));
			return;
		}
		if (!bRequestSuccess || !bValid)
		{
			Panel->CompleteRequest(TEXT("Code invalid or validation unavailable."));
			return;
		}

		Manager->RedeemGiftCode(Code, [WeakThis, WeakGI, WeakHM, Code, Generation, Owner](bool bSuccess, const FString& GiftData, const FString& /*Message*/)
		{
			USeagullGameInstance* Instance = WeakGI.Get();
			USeagullHorizonManager* Manager = WeakHM.Get();
			USeagullGiftCodePanel* Panel = WeakThis.Get();
			// Once consumed, apply to the original save even if the modal was closed.
			// Never apply a late response to another player or the practice economy.
			if (!Instance || !Manager || Instance->SessionGeneration != Generation || Instance->SaveOwnerId != Owner
				|| Instance->bPracticeMode || Manager->GetUserId() != Owner || !Instance->CanMutateProgress()) return;
			if (!bSuccess)
			{
				if (Panel && Panel->IsInViewport()) Panel->CompleteRequest(TEXT("Redemption failed."));
				return;
			}
			Instance->SaveData.GiftCodesRedeemed.AddUnique(Code);
			int32 CoinReward = 0;
			TSharedPtr<FJsonObject> JsonObj;
			double CoinValue = 0.0;
			if (FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(GiftData), JsonObj) && JsonObj.IsValid()
				&& JsonObj->TryGetNumberField(TEXT("coins"), CoinValue) && FMath::IsFinite(CoinValue)
				&& CoinValue > 0.0 && CoinValue <= static_cast<double>(MAX_int32))
			{
				const int32 WholeCoins = static_cast<int32>(CoinValue);
				if (CoinValue == static_cast<double>(WholeCoins))
					CoinReward = FMath::Min(WholeCoins, MAX_int32 - FMath::Max(0, Instance->SaveData.Coins));
			}
			Instance->SaveData.Coins += CoinReward;
			const FString RewardText = CoinReward > 0 ? FString::Printf(TEXT("Code redeemed! +%d coins"), CoinReward)
				: FString(TEXT("Code redeemed. No coin reward; cosmetic unlocks appear in your profile."));
			if (Panel && Panel->IsInViewport())
			{
				Panel->CompleteRequest(RewardText + TEXT(" / syncing cloud save..."));
				if (ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(UGameplayStatics::GetPlayerController(Panel->GetWorld(), 0))) PC->RefreshHubDisplay();
			}
			Manager->SaveData(Instance->SaveData.ToJsonString(), [WeakThis, WeakGI, Generation, Owner, RewardText](bool bSaved)
			{
				USeagullGameInstance* Instance = WeakGI.Get();
				if (!Instance || Instance->SessionGeneration != Generation || Instance->SaveOwnerId != Owner || Instance->bPracticeMode) return;
				if (USeagullGiftCodePanel* CurrentPanel = WeakThis.Get())
					if (CurrentPanel->IsInViewport()) CurrentPanel->CompleteRequest(RewardText + (bSaved ? TEXT(" / saved") : TEXT(" / cloud save failed; reward retained in memory")));
			});
		});
	});
}

void USeagullGiftCodePanel::CompleteRequest(const FString& Message)
{
	bRedeeming = false;
	if (RedeemButton) RedeemButton->SetIsEnabled(true);
	if (StatusText) StatusText->SetText(FText::FromString(Message));
}

void USeagullGiftCodePanel::OnCloseClicked()
{
	RemoveFromParent();
}
