#include "TekhneRTReadbackManager.h"
#include "TextureResource.h"
#include "RHICommandList.h"

UCanvasRenderTarget2D* TekhneRTReadbackManager::RenderTarget = nullptr;
TUniquePtr<FRHIGPUTextureReadback> TekhneRTReadbackManager::Readback = nullptr;
TArray<float> TekhneRTReadbackManager::CachedData;
bool TekhneRTReadbackManager::bDataReady = false;
bool TekhneRTReadbackManager::bInFlight = false;

void TekhneRTReadbackManager::Init(UCanvasRenderTarget2D* InRenderTarget)
{
    RenderTarget = InRenderTarget;
    CachedData.Empty();
    bDataReady = false;
    bInFlight = false;
    if (!Readback.IsValid())
    {
        Readback = MakeUnique<FRHIGPUTextureReadback>(TEXT("TekhneGPUReadback"));
    }
}

void TekhneRTReadbackManager::Tick()
{
    if (!RenderTarget || !Readback.IsValid()) return;

    if (!bInFlight)
    {
        // Start a new readback
        FTextureRenderTargetResource* RTResource = RenderTarget->GameThread_GetRenderTargetResource();
        if (RTResource)
        {
            ENQUEUE_RENDER_COMMAND(EnqueueReadback)(
                [RTResource, ReadbackPtr = Readback.Get()](FRHICommandListImmediate& RHICmdList)
                {
                    ReadbackPtr->EnqueueCopy(
                        RHICmdList,
                        RTResource->GetRenderTargetTexture(),
                        FIntVector(0, 0, 0),
                        0,
                        FIntVector(RTResource->GetSizeX(), RTResource->GetSizeY(), 1)
                    );
                }
                );
            bInFlight = true;
        }
    }
    else if (Readback->IsReady())
    {
        int32 Width = RenderTarget->SizeX;
        int32 Height = RenderTarget->SizeY;
        int32 RowPitchInPixels = 0;
        void* DataPtr = Readback->Lock(RowPitchInPixels);

        if (DataPtr)
        {
            CachedData.Empty(Width * Height);

            if (RowPitchInPixels == Width || RowPitchInPixels == 0)
            {
                FFloat16* Float16Data = static_cast<FFloat16*>(DataPtr);
                for (int32 i = 0; i < Width * Height; ++i)
                {
                    CachedData.Add(Float16Data[i].GetFloat());
                }
            }
            else
            {
                for (int32 y = 0; y < Height; y++)
                {
                    FFloat16* Row = reinterpret_cast<FFloat16*>((uint8*)DataPtr + y * RowPitchInPixels * sizeof(FFloat16));
                    for (int32 x = 0; x < Width; x++)
                    {
                        CachedData.Add(Row[x].GetFloat());
                    }
                }
            }
            Readback->Unlock();
            bDataReady = true;
        }
        bInFlight = false; // allow new readback on next Tick
    }
}

TArray<float> TekhneRTReadbackManager::GetLatestData()
{
    return CachedData;
}

bool TekhneRTReadbackManager::IsDataReady()
{
    return bDataReady;
}

void TekhneRTReadbackManager::Stop()
{
    RenderTarget = nullptr;
    Readback.Reset();
    CachedData.Empty();
    bDataReady = false;
    bInFlight = false;
}
