#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullGameOverScreen.generated.h"

class UButton;
class UTextBlock;

UCLASS()
class USeagullGameOverScreen : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;
	virtual void NativeConstruct() override;

	void SetRank(int32 Rank);
	void LoadGameOverData();

	// Result line of the score submit, for example "Validated run" or why the server refused it.
	void SetScoreStatus(const FString& Message, bool bIsError);

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* ScoreText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* WavesText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* LevelText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* CoinsText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* RankText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* BestText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* ScoreStatusText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* PlayAgainButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* HubButton = nullptr;

private:
	UFUNCTION()
	void OnPlayAgainClicked();

	UFUNCTION()
	void OnHubClicked();

};
