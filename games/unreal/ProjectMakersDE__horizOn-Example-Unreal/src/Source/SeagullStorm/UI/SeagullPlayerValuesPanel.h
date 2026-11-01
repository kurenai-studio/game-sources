#pragma once
#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Models/HorizonPlayerValues.h"
#include "SeagullPlayerValuesPanel.generated.h"
class UTextBlock;
class UEditableTextBox;
class UHorizonSubsystem;
class USeagullValueIntent;
/** Explicit server balances and catalog purchases, separate from local practice coins. */
UCLASS()
class USeagullPlayerValuesPanel : public UUserWidget
{
    GENERATED_BODY()
public:
    virtual void NativeOnInitialized() override;
    virtual void NativeTick(const FGeometry& Geometry, float DeltaTime) override;
private:
    UPROPERTY() UTextBlock* Status = nullptr;
    UPROPERTY() UTextBlock* Balances = nullptr;
    UPROPERTY() UTextBlock* Catalog = nullptr;
    UPROPERTY() UEditableTextBox* OfferInput = nullptr;
    UPROPERTY() UEditableTextBox* KeyInput = nullptr;
    UPROPERTY() UEditableTextBox* AmountInput = nullptr;
    UPROPERTY() USeagullValueIntent* Pending = nullptr;
    FHorizonPlayerValuesOffers Offers;
    FString Context;
    int64 Generation = 0;
    int64 RetryQuotedVersion = -1;
    FString RetryQuotedOperation;
    bool bBusy = false;
    UFUNCTION() void OnState();
    UFUNCTION() void OnOffers();
    UFUNCTION() void OnPurchase();
    UFUNCTION() void OnAdjust();
    UFUNCTION() void OnRetry();
    UFUNCTION() void OnClose();
    UHorizonSubsystem* Begin();
    FString CurrentContext() const;
    bool IsCurrent(const FString& Expected, int64 SentGeneration) const;
    bool LoadPending(UHorizonSubsystem* SDK);
    void SendPending(UHorizonSubsystem* SDK);
    void DisplayState(bool Success, const FHorizonPlayerValuesState& State, const FString& Code);
    void DisplayOffers(const FHorizonPlayerValuesOffers& Snapshot);
    void Message(const FString& Text, bool Success = false);
};
