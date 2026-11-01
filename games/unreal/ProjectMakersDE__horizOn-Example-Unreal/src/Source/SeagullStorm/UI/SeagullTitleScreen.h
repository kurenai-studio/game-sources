#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullTitleScreen.generated.h"

class UButton;
class UTextBlock;
class UEditableTextBox;
class UImage;

UCLASS()
class USeagullTitleScreen : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual void NativeOnInitialized() override;
	virtual void NativeConstruct() override;

protected:
	UPROPERTY(meta = (BindWidgetOptional))
	UImage* LogoImage = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* TitleText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* SubtitleText = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UEditableTextBox* NameInput = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* GuestButton = nullptr;

	UPROPERTY()
	UButton* PracticeButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* GoogleButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* AppleButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* EmailButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UButton* RegisterButton = nullptr;

	UPROPERTY(meta = (BindWidgetOptional))
	UTextBlock* StatusText = nullptr;

private:
	UFUNCTION()
	void OnGuestClicked();

	UFUNCTION()
	void OnPracticeClicked();

	UFUNCTION()
	void OnGoogleClicked();

	UFUNCTION()
	void OnAppleClicked();

	UFUNCTION()
	void OnEmailClicked();

	UFUNCTION()
	void OnRegisterClicked();

	void OnAuthSuccess(bool bKnownNewPlayer = false);
	void OnAuthFailure();
};
