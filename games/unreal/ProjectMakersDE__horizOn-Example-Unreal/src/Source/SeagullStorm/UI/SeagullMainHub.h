#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Models/HorizonNewsEntry.h"
#include "SeagullMainHub.generated.h"

class UButton;
class UTextBlock;
class UVerticalBox;

UCLASS()
class USeagullMainHub : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;
	virtual void NativeConstruct() override;
	virtual void NativeTick(const FGeometry& Geometry, float DeltaTime) override;

	// Re-renders coins/highscore/upgrade labels from GameInstance state. Public so
	// out-of-hub changes (e.g. a gift code redemption) can refresh the display.
	void RefreshDisplay();

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UButton* PlayButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* GiftCodeButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* FeedbackButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* SettingsButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* CoinsText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* HighscoreText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UVerticalBox* LeaderboardBox = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UVerticalBox* NewsBox = nullptr;

	// Upgrade panel rows (label shows level + next cost, button buys)
	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* SpeedLevelText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* DamageLevelText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* HPLevelText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* MagnetLevelText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* BuySpeedButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* BuyDamageButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* BuyHPButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* BuyMagnetButton = nullptr;

private:
	UFUNCTION()
	void OnPlayClicked();

	UFUNCTION()
	void OnGiftCodeClicked();

	UFUNCTION()
	void OnFeedbackClicked();

	UFUNCTION()
	void OnSettingsClicked();

	UFUNCTION()
	void OnSDKClicked();

    UFUNCTION()
    void OnPlayerValuesClicked();
    UFUNCTION() void OnStatisticsClicked();

	UPROPERTY()
	UTextBlock* SessionText = nullptr;

	UPROPERTY()
	UButton* SDKButton = nullptr;

	void LoadHubData();

	// Upgrade buttons
	UFUNCTION()
	void OnBuySpeed();
	UFUNCTION()
	void OnBuyDamage();
	UFUNCTION()
	void OnBuyHP();
	UFUNCTION()
	void OnBuyMagnet();

	void TryBuyUpgrade(const FString& Key);
	void DisplayNews(const TArray<FHorizonNewsEntry>& Entries);

	class UWidget* BuildUpgradeRow(UTextBlock*& OutLevelText, UButton*& OutBuyButton,
		const FString& RowName);
	void UpdateUpgradeRow(UTextBlock* LevelText, const FString& Label, const FString& Key);
};
