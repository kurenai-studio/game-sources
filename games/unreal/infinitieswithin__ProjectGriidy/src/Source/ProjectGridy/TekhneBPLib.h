#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "Engine/CanvasRenderTarget2D.h"
#include "TekhneBPLib.generated.h"

UCLASS()
class PROJECTGRIDY_API UTekhneBPLib : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()
public:
    UFUNCTION(BlueprintCallable, Category = "Tekhne")
    static void StartRTReadback(UCanvasRenderTarget2D* RenderTarget);

    UFUNCTION(BlueprintCallable, Category = "Tekhne")
    static void TickRTReadback(); // You must call this regularly

    UFUNCTION(BlueprintCallable, Category = "Tekhne")
    static TArray<float> GetLatestRTData();

    UFUNCTION(BlueprintCallable, Category = "Tekhne")
    static bool IsRTDataReady();

    UFUNCTION(BlueprintCallable, Category = "Tekhne")
    static void StopRTReadback();
};
