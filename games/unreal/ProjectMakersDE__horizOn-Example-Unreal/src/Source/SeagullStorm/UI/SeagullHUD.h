#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullHUD.generated.h"

class UTextBlock;
class UProgressBar;
class UButton;

UCLASS()
class USeagullHUD : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;
	virtual void NativeConstruct() override;
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* WaveText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* TimerText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* ScoreText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* LevelText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UProgressBar* HPBar = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UProgressBar* XPBar = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* PauseButton = nullptr;

private:
	UPROPERTY()
	UTextBlock* RunStatusText = nullptr;
	UFUNCTION()
	void OnPauseClicked();
};
