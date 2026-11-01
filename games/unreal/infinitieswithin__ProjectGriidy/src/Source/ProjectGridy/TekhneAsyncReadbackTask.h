#pragma once

#include "CoreMinimal.h"
#include "Engine/CanvasRenderTarget2D.h"
#include "RHIGPUReadback.h"
#include "Async/AsyncWork.h"

class FTekhneAsyncReadbackTask : public FNonAbandonableTask
{
public:
    FTekhneAsyncReadbackTask(UCanvasRenderTarget2D* InRenderTarget);

    void DoWork();

    FORCEINLINE TStatId GetStatId() const
    {
        RETURN_QUICK_DECLARE_CYCLE_STAT(FTekhneAsyncReadbackTask, STATGROUP_ThreadPoolAsyncTasks);
    }

    static TArray<float> GetCachedData();
    static bool IsDataReady();
    static void Stop();

private:
    UCanvasRenderTarget2D* RenderTarget;
    static TUniquePtr<FRHIGPUTextureReadback> GPUTextureReadback;
    static TArray<float> CachedData;
    static FCriticalSection DataCriticalSection;
    static TAtomic<bool> bDataReady;
    static TAtomic<bool> bShouldStop;
};
