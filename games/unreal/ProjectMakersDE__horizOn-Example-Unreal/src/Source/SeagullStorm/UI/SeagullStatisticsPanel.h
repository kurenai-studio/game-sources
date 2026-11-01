#pragma once
#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SeagullStatisticsPanel.generated.h"
class UTextBlock;
/** Explicit HTTP actions; tick only renders the local current SDK snapshot. */
UCLASS()
class USeagullStatisticsPanel : public UUserWidget
{
    GENERATED_BODY()
public:
    virtual void NativeOnInitialized() override;
    virtual void NativeTick(const FGeometry& Geometry,float DeltaTime) override;
    bool bHelloDemo=false;
    void EnableHelloDemo();
private:
    UPROPERTY() UTextBlock* Values=nullptr;
    UPROPERTY() UTextBlock* Status=nullptr;
    float RenderAfter=0;
    UFUNCTION() void OnRefresh();
    UFUNCTION() void OnRetry();
    UFUNCTION() void OnDemo();
    UFUNCTION() void OnClose();
    void Render();
};
