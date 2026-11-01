#include "TekhneAsyncReadbackTask.h"
#include "RHICommandList.h"
#include "TextureResource.h"

TUniquePtr<FRHIGPUTextureReadback> FTekhneAsyncReadbackTask::GPUTextureReadback = nullptr;
TArray<float> FTekhneAsyncReadbackTask::CachedData;
FCriticalSection FTekhneAsyncReadbackTask::DataCriticalSection;
TAtomic<bool> FTekhneAsyncReadbackTask::bDataReady(false);
TAtomic<bool> FTekhneAsyncReadbackTask::bShouldStop(false);

FTekhneAsyncReadbackTask::FTekhneAsyncReadbackTask(UCanvasRenderTarget2D* InRenderTarget)
    : RenderTarget(InRenderTarget)
{
    if (!GPUTextureReadback.IsValid())
    {
        GPUTextureReadback = MakeUnique<FRHIGPUTextureReadback>(TEXT("TekhneGPUReadback"));
    }
}

void FTekhneAsyncReadbackTask::DoWork()
{
    if (bShouldStop)
        return;

    if (!RenderTarget || !GPUTextureReadback.IsValid())
        return;

    FTextureRenderTargetResource* RTResource = RenderTarget->GameThread_GetRenderTargetResource();
    if (!RTResource)
        return;

    ENQUEUE_RENDER_COMMAND(EnqueueReadback)(
        [RTResource](FRHICommandListImmediate& RHICmdList)
        {
            GPUTextureReadback->EnqueueCopy(
                RHICmdList,
                RTResource->GetRenderTargetTexture(),
                FIntVector(0, 0, 0),
                0,
                FIntVector(RTResource->GetSizeX(), RTResource->GetSizeY(), 1)
            );
        }
        );

    while (!GPUTextureReadback->IsReady())
    {
        if (bShouldStop) return;
        FPlatformProcess::Sleep(0.005f);
    }

    int32 Width = RenderTarget->SizeX;
    int32 Height = RenderTarget->SizeY;
    int32 RowPitchInPixels = 0;
    void* DataPtr = GPUTextureReadback->Lock(RowPitchInPixels);

    if (DataPtr)
    {
        TArray<float> TempData;
        TempData.Reserve(Width * Height);

        if (RowPitchInPixels == Width || RowPitchInPixels == 0)
        {
            FFloat16* Float16Data = static_cast<FFloat16*>(DataPtr);
            for (int32 i = 0; i < Width * Height; ++i)
            {
                TempData.Add(Float16Data[i].GetFloat());
            }
        }
        else
        {
            for (int32 y = 0; y < Height; y++)
            {
                FFloat16* Row = reinterpret_cast<FFloat16*>((uint8*)DataPtr + y * RowPitchInPixels * sizeof(FFloat16));
                for (int32 x = 0; x < Width; x++)
                {
                    TempData.Add(Row[x].GetFloat());
                }
            }
        }

        GPUTextureReadback->Unlock();

        {
            FScopeLock Lock(&DataCriticalSection);
            CachedData = MoveTemp(TempData);
            bDataReady = true;
        }
    }

    if (!bShouldStop)
    {
        (new FAutoDeleteAsyncTask<FTekhneAsyncReadbackTask>(RenderTarget))->StartBackgroundTask();
    }
}

TArray<float> FTekhneAsyncReadbackTask::GetCachedData()
{
    FScopeLock Lock(&DataCriticalSection);
    return CachedData;
}

bool FTekhneAsyncReadbackTask::IsDataReady()
{
    return bDataReady;
}

void FTekhneAsyncReadbackTask::Stop()
{
    bShouldStop = true;
}
