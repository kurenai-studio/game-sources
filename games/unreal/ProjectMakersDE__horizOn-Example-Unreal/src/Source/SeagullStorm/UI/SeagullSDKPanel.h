#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullSDKPanel.generated.h"

class UTextBlock;
class UEditableTextBox;
class USeagullHorizonManager;

/** Small interactive reference for the SDK APIs used by the game. */
UCLASS()
class USeagullSDKPanel : public UUserWidget
{
    GENERATED_BODY()
public:
    virtual void NativeOnInitialized() override;
    virtual void NativeTick(const FGeometry& Geometry, float DeltaTime) override;
private:
    UPROPERTY() UTextBlock* ResultText = nullptr;
    UPROPERTY() UTextBlock* EvidenceText = nullptr;
    UPROPERTY() UEditableTextBox* BoardInput = nullptr;
    UPROPERTY() UEditableTextBox* AvatarInput = nullptr;
    UPROPERTY() UEditableTextBox* EmailTemplateInput = nullptr;
    UFUNCTION() void OnProfile();
    UFUNCTION() void OnApplyAvatar();
    UFUNCTION() void OnSendEmail();
    bool bBusy = false;
    USeagullHorizonManager* BeginRequest(const FString& Action);
    void ShowResult(const FString& Text, bool bSuccess);
    UFUNCTION() void OnBoards();
    UFUNCTION() void OnTop();
    UFUNCTION() void OnAround();
    UFUNCTION() void OnRank();
    UFUNCTION() void OnState();
    UFUNCTION() void OnEnglish();
    UFUNCTION() void OnGerman();
    UFUNCTION() void OnCloudSave();
    UFUNCTION() void OnClose();
    void LoadLanguage(const FString& Language);
};
