#include "TekhneBPLib.h"
#include "TekhneRTReadbackManager.h"

void UTekhneBPLib::StartRTReadback(UCanvasRenderTarget2D* RenderTarget)
{
    TekhneRTReadbackManager::Init(RenderTarget);
}
void UTekhneBPLib::TickRTReadback()
{
    TekhneRTReadbackManager::Tick();
}
TArray<float> UTekhneBPLib::GetLatestRTData()
{
    return TekhneRTReadbackManager::GetLatestData();
}
bool UTekhneBPLib::IsRTDataReady()
{
    return TekhneRTReadbackManager::IsDataReady();
}
void UTekhneBPLib::StopRTReadback()
{
    TekhneRTReadbackManager::Stop();
}
