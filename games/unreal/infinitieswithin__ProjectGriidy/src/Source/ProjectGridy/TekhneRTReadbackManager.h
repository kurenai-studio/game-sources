#pragma once

#include "CoreMinimal.h"
#include "Engine/CanvasRenderTarget2D.h"
#include "RHIGPUReadback.h"

class TekhneRTReadbackManager
{
public:
    static void Init(UCanvasRenderTarget2D* InRenderTarget);
    static void Tick(); // Call this each frame from your game, actor, or a Blueprint custom event timer
    static TArray<float> GetLatestData();
    static bool IsDataReady();
    static void Stop();

private:
    static UCanvasRenderTarget2D* RenderTarget;
    static TUniquePtr<FRHIGPUTextureReadback> Readback;
    static TArray<float> CachedData;
    static bool bDataReady;
    static bool bInFlight;
};
