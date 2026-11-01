#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullEmailAuthForm.generated.h"

class UEditableTextBox;
class UButton;
class UTextBlock;

UCLASS()
class USeagullEmailAuthForm : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;
	virtual void NativeConstruct() override;

	bool bRegisterMode = false;

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UEditableTextBox* EmailInput = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UEditableTextBox* PasswordInput = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UEditableTextBox* UsernameInput = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* SubmitButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* CloseButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* TitleLabel = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* StatusText = nullptr;

private:
	UFUNCTION()
	void OnSubmitClicked();

	UFUNCTION()
	void OnCloseClicked();

	void OnAuthResult(bool bSuccess);
};
