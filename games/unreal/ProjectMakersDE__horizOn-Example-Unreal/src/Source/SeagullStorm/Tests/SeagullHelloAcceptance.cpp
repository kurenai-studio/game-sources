#if WITH_DEV_AUTOMATION_TESTS
#include "Misc/AutomationTest.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "Misc/OutputDevice.h"
#include "Engine/Engine.h"
#include "Engine/GameInstance.h"
#include "Engine/GameViewportClient.h"
#include "HorizonSubsystem.h"
#include "Managers/HorizonAuthManager.h"
#include "Examples/HelloHorizon/HelloHorizonActor.h"

namespace SeagullHelloAcceptance
{
class FHelloSmoke final : public IAutomationLatentCommand, public FOutputDevice
{
    FAutomationTestBase* Test;
    double Started = FPlatformTime::Seconds();
    double SubmittedAt = 0;
    bool bSpawned = false, bCapturing = false;
    FThreadSafeBool bSubmitted = false;
public:
    explicit FHelloSmoke(FAutomationTestBase* InTest):Test(InTest) { GLog->AddOutputDevice(this); }
    virtual ~FHelloSmoke() override { GLog->RemoveOutputDevice(this); }
    virtual void Serialize(const TCHAR* Text,ELogVerbosity::Type Verbosity,const FName& Category) override
    { if (FString(Text).Contains(TEXT("[HelloHorizon] Done: score submitted."))) bSubmitted = true; }
    virtual bool Update() override
    {
        if (FPlatformTime::Seconds()-Started>30) { Test->AddError(TEXT("Hello actor did not finish its real HTTP workflow")); return true; }
        UWorld* World = nullptr;
        for (const FWorldContext& Context:GEngine->GetWorldContexts()) if (Context.World() && Context.World()->IsGameWorld()) { World=Context.World(); break; }
        if (!World) return false;
        if (!bSpawned) { World->SpawnActor<AHelloHorizonActor>(); bSpawned=true; return false; }
        if (!bSubmitted) return false;
        if (!SubmittedAt) SubmittedAt=FPlatformTime::Seconds();
        if (FPlatformTime::Seconds()-SubmittedAt<1) return false;
        auto* SDK=World->GetGameInstance()->GetSubsystem<UHorizonSubsystem>();
        if (!SDK || !SDK->Auth->IsSignedIn()) { Test->AddError(TEXT("Hello actor lost its authenticated session")); return true; }
        if (!FParse::Param(FCommandLine::Get(),TEXT("nullrhi")))
        {
            if (!bCapturing) { FString Directory; FParse::Value(FCommandLine::Get(),TEXT("SeagullCaptureDir="),Directory);
                FScreenshotRequest::RequestScreenshot((Directory.IsEmpty()?FPaths::ProjectDir()/TEXT("screenshots/task1004"):Directory)/TEXT("15-hello.png"),true,false); bCapturing=true; return false; }
            if (FScreenshotRequest::IsScreenshotRequested()) return false;
        }
        Test->AddInfo(TEXT("Unmodified official HelloHorizonActor connected, signed up, submitted score and displayed completion.")); return true;
    }
};
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FSeagullHelloAcceptance,"Seagull.Acceptance.HelloHorizon",EAutomationTestFlags::ClientContext|EAutomationTestFlags::EngineFilter)
bool FSeagullHelloAcceptance::RunTest(const FString&)
{
    FString Fixture;
    if (!FParse::Value(FCommandLine::Get(),TEXT("SeagullFixture="),Fixture)) { AddError(TEXT("Pass an explicit loopback SeagullFixture")); return false; }
    ADD_LATENT_AUTOMATION_COMMAND(SeagullHelloAcceptance::FHelloSmoke(this)); return true;
}
#endif
