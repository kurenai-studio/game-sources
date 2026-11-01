#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullFeedbackForm.generated.h"

class UEditableTextBox;
class UButton;
class UComboBoxString;
class UTextBlock;

UCLASS()
class USeagullFeedbackForm : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;
	virtual void NativeConstruct() override;

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UEditableTextBox* TitleInput = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UEditableTextBox* MessageInput = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UComboBoxString* CategoryDropdown = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* SubmitButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* CloseButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* StatusText = nullptr;

private:
	UFUNCTION()
	void OnSubmitClicked();

	UFUNCTION()
	void OnCloseClicked();
};
