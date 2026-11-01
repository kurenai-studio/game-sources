#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Core/SeagullTypes.h"
#include "SeagullLevelUpOverlay.generated.h"

class UButton;
class UTextBlock;

UCLASS()
class USeagullLevelUpOverlay : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;

	void SetChoices(const TArray<FSeagullLevelUpChoice>& InChoices);

private:
	TArray<FSeagullLevelUpChoice> Choices;

	UFUNCTION()
	void OnChoice1();
	UFUNCTION()
	void OnChoice2();
	UFUNCTION()
	void OnChoice3();

	void SelectChoice(int32 Index);

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UButton* Choice1Button = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* Choice2Button = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* Choice3Button = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* Choice1Text = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* Choice2Text = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* Choice3Text = nullptr;
};
