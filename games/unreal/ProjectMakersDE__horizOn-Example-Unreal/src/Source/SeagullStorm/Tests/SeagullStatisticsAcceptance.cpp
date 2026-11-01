#if WITH_DEV_AUTOMATION_TESTS
#include "Misc/AutomationTest.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "ShaderCompiler.h"
#include "AssetCompilingManager.h"
#include "Engine/Engine.h"
#include "Engine/GameViewportClient.h"
#include "Kismet/GameplayStatics.h"
#include "Blueprint/WidgetBlueprintLibrary.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullStormGameState.h"
#include "Data/SeagullConfigCache.h"
#include "Data/SeagullStatisticsIntent.h"
#include "Examples/HorizonExampleIdentity.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Horizon/SeagullStatisticsSession.h"
#include "UI/SeagullStatisticsPanel.h"
#include "Hello/SeagullStatisticsHelloActor.h"
#include "HorizonSubsystem.h"
#include "HorizonSessionSave.h"
#include "Http/HorizonHttpClient.h"
#include "Managers/HorizonAuthManager.h"
#include "Managers/HorizonStatisticsManager.h"
namespace SeagullStatisticsAcceptance
{
static UWorld* GameWorld()
{ for (const FWorldContext& C:GEngine->GetWorldContexts()) if (C.World() && C.World()->IsGameWorld()) return C.World(); return nullptr; }
static void Invoke(UObject* Object,const TCHAR* Name)
{ if (Object) if (auto* Function=Object->FindFunction(FName(Name))) Object->ProcessEvent(Function,nullptr); }
static int64 Value(const FHorizonStatisticsSnapshot& S,const FString& Key)
{ for (const auto& V:S.Values) if (V.Key==Key) return V.Value; return -1; }
static USeagullStatisticsPanel* Panel(UWorld* World)
{ TArray<UUserWidget*> Widgets; UWidgetBlueprintLibrary::GetAllWidgetsOfClass(World,Widgets,USeagullStatisticsPanel::StaticClass()); for (auto* W:Widgets) if (W->IsInViewport()) return Cast<USeagullStatisticsPanel>(W); return nullptr; }
struct FCapture
{
    bool Waiting=false;
    bool Take(const TCHAR* Name)
    {
        if (FParse::Param(FCommandLine::Get(),TEXT("nullrhi"))) return true;
        if (GShaderCompilingManager && GShaderCompilingManager->IsCompiling()) return false;
        if (!Waiting)
        { FString Directory; FParse::Value(FCommandLine::Get(),TEXT("SeagullCaptureDir="),Directory); FScreenshotRequest::RequestScreenshot(Directory/Name,true,false); Waiting=true; return false; }
        if (FScreenshotRequest::IsScreenshotRequested()) return false; Waiting=false; return true;
    }
};
class FRound final : public IAutomationLatentCommand
{
    FAutomationTestBase* Test; int32 Step=0; double Started=FPlatformTime::Seconds(),Since=Started; bool AuthDone=false,AuthOk=false; FCapture Capture;
    FString OriginalId,ExpiredId,OriginalAnonymousToken;
    UHorizonExampleIdentity* RecoveryOriginal=nullptr;
    void Next() { ++Step; Since=FPlatformTime::Seconds(); }
public:
    explicit FRound(FAutomationTestBase* T):Test(T) {}
    virtual bool Update() override
    {
        if (FPlatformTime::Seconds()-Started>75) { Test->AddError(FString::Printf(TEXT("Statistics round timeout step%d"),Step)); return true; }
        auto* World=GameWorld(); if (!World) return false;
        auto* GI=Cast<USeagullGameInstance>(World->GetGameInstance()); auto* GM=Cast<ASeagullStormGameMode>(World->GetAuthGameMode()); auto* GS=World->GetGameState<ASeagullStormGameState>();
        if (!GI || !GM || !GS) return false; auto* SDK=GI->GetHorizonSubsystem(); auto* Flow=GI->GetStatisticsSession(); auto* HM=GI->GetHorizonManager(); const auto Key=SDK->GetHttpClient()->GetApiKey(); const auto User=SDK->Auth->GetCurrentUser().UserId;
        const double Elapsed=FPlatformTime::Seconds()-Since; auto Fail=[&](const FString& Error) { Test->AddError(Error); return true; };
        switch (Step)
        {
        case 0:
            if (!HM->IsConnected() || Elapsed<1) return false; FAssetCompilingManager::Get().FinishAllCompilation();
            HM->SignUpAnonymous(TEXT("StatisticsFixture"),[this](bool Ok) { AuthDone=true; AuthOk=Ok; }); Next(); break;
        case 1:
            if (!AuthDone) return false; if (!AuthOk) return Fail(TEXT("Original synthetic guest signup failed"));
            GI->BeginOnlineSession(true); GI->bCloudSaveReady=false; GI->GetConfigCache()->bValidatedActionsEnabled=false;
            GM->StartRun(); if (!GS->bRunActive) return Fail(TEXT("Online round did not start")); GS->AddKill(); GS->AddKill(); GS->AddScore(8); GM->EndRun(true); Next(); break;
        case 2:
            if (Flow->IsBusy() || SDK->Statistics->GetLastErrorCode()!=TEXT("TEMPORARY")) return false;
            {
                bool Blocked; auto* P=USeagullStatisticsIntent::Load(Key,User,Blocked); if (!P || Blocked || P->Updates[0].Value!=2) return Fail(TEXT("Uncertain actual round batch was not retained")); OriginalId=P->OperationId;
                P->Updates[0].Value=3; if (P->Persist(Key)) return Fail(TEXT("Conflicting payload replaced saved original"));
                auto* Original=USeagullStatisticsIntent::Load(Key,User,Blocked); if (!Original || Original->Updates[0].Value!=2 || Original->OperationId!=OriginalId) return Fail(TEXT("Original payload/ID changed after conflict"));
                if (USeagullStatisticsIntent::Load(Key+TEXT("other-project"),User,Blocked) || Blocked) return Fail(TEXT("Another project inherited the pending batch"));
            }
            GM->StartRun(); if (GS->bRunActive || !Panel(World)) return Fail(TEXT("Uncertain batch did not block next online round/show recovery")); Next(); break;
        case 3:
            if (Elapsed<.5) return false; if (!Capture.Take(TEXT("17-statistics-original.png"))) return false;
            Invoke(Panel(World),TEXT("OnRefresh")); Next(); break;
        case 4:
            if (Flow->IsBusy() || Value(Flow->Snapshot(),TEXT("kills"))!=2 || Elapsed<.5) return false;
            if (!Flow->HasPending()) return Fail(TEXT("Snapshot must not discard an uncertain batch"));
            if (!Capture.Take(TEXT("18-statistics-snapshot.png"))) return false; Invoke(Panel(World),TEXT("OnRetry")); Next(); break;
        case 5:
            if (Flow->IsBusy() || Flow->HasPending() || !Flow->Snapshot().bReplayed || Elapsed<.5) return false;
            if (Value(Flow->Snapshot(),TEXT("kills"))!=2 || Value(Flow->Snapshot(),TEXT("rounds"))!=1 || Value(Flow->Snapshot(),TEXT("best_score"))!=10) return Fail(TEXT("Replay added local deltas or duplicate counters"));
            if (!Capture.Take(TEXT("19-statistics-replay.png"))) return false;
            if (auto* W=Panel(World)) W->RemoveFromParent(); GM->StartRun(); if (!GS->bRunActive) return Fail(TEXT("Confirmed batch did not reopen online rounds")); GM->EndRun(true); Next(); break;
        case 6:
            if (Flow->IsBusy() || SDK->Statistics->GetLastErrorCode()!=TEXT("OPERATION_EXPIRED")) return false;
            { bool Blocked; auto* P=USeagullStatisticsIntent::Load(Key,User,Blocked); if (!P || Blocked || P->OperationId==OriginalId) return Fail(TEXT("Expired later round original was not retained")); ExpiredId=P->OperationId; }
            GM->StartRun(); if (GS->bRunActive || !Panel(World)) return Fail(TEXT("Expired batch allowed silent new booking")); Invoke(Panel(World),TEXT("OnRetry")); Next(); break;
        case 7:
            if (Flow->IsBusy() || Elapsed<.5) return false;
            { bool Blocked; auto* P=USeagullStatisticsIntent::Load(Key,User,Blocked); if (!P || Blocked || P->OperationId!=ExpiredId) return Fail(TEXT("Explicit expired retry invented a new ID")); }
            if (!Flow->GetStatus().Contains(TEXT("OPERATION_EXPIRED"))) return Fail(TEXT("Expired outcome not visible to player"));
            if (!Capture.Take(TEXT("21-statistics-expired.png"))) return false;
            Flow->Refresh(); GI->BeginPractice(); Next(); break;
        case 8:
            if (Elapsed<.6) return false;
            if (Flow->Snapshot().bValid || Flow->RecordRound(3,1200)) return Fail(TEXT("Practice exposed/refilled server state or reported a batch"));
            {
                auto* Saved=UHorizonSessionSave::LoadFromDisk(); if (!Saved) return Fail(TEXT("Guest session missing before recovery regression"));
                OriginalAnonymousToken=Saved->CachedAnonymousToken;
                if (!Saved->SaveToDisk() || !UHorizonExampleIdentity::CaptureBeforeAuth(SDK,RecoveryOriginal)) return Fail(TEXT("Validated original guest credential could not be protected"));
                UHorizonSessionSave::DeleteFromDisk(); AuthDone=false; AuthOk=true;
                HM->RestoreSession([this](bool Ok) { AuthDone=true; AuthOk=Ok; });
            }
            Next(); break;
        case 9:
            if (!AuthDone) return false;
            if (AuthOk || !HM->HasProtectedGuestIdentity()) return Fail(TEXT("Failed protected guest restore lost its persistent identity guard"));
            { auto* Saved=UHorizonSessionSave::LoadFromDisk(); if (!Saved || Saved->CachedAnonymousToken!=OriginalAnonymousToken) return Fail(TEXT("SDK cache loss discarded the validated original guest recovery credential")); }
            AuthDone=false; AuthOk=true; HM->SignUpAnonymous(TEXT("MustNotCreateReplacement"),[this](bool Ok) { AuthDone=true; AuthOk=Ok; });
            if (!AuthDone || AuthOk) return Fail(TEXT("Known original identity permitted replacement signup"));
            Test->AddInfo(TEXT("Actual completed online rounds, durable same-ID lost-receipt replay, expired original retention, practice fence and protected guest recovery/signup prevention passed.")); return true;
        }
        return false;
    }
};
class FHello final : public IAutomationLatentCommand
{
    FAutomationTestBase* Test; int32 Step=0; double Started=FPlatformTime::Seconds(),Since=Started; FCapture Capture;
    void Next() { ++Step; Since=FPlatformTime::Seconds(); }
public:
    explicit FHello(FAutomationTestBase* T):Test(T) {}
    virtual bool Update() override
    {
        if (FPlatformTime::Seconds()-Started>45) { Test->AddError(FString::Printf(TEXT("Hello statistics timeout step%d"),Step)); return true; }
        auto* World=GameWorld(); if (!World) return false; auto* GI=Cast<USeagullGameInstance>(World->GetGameInstance()); if (!GI) return false; auto* Flow=GI->GetStatisticsSession();
        switch (Step)
        {
        case 0:World->SpawnActor<ASeagullStatisticsHelloActor>(); Next(); break;
        case 1:if (!Panel(World) || FPlatformTime::Seconds()-Since<1) return false; Invoke(Panel(World),TEXT("OnRefresh")); Next(); break;
        case 2:if (Flow->IsBusy() || !Flow->Snapshot().bValid) return false; Invoke(Panel(World),TEXT("OnDemo")); Next(); break;
        case 3:
            if (Flow->IsBusy() || Flow->HasPending() || Value(Flow->Snapshot(),TEXT("kills"))!=3 || FPlatformTime::Seconds()-Since<1) return false;
            if (Value(Flow->Snapshot(),TEXT("rounds"))!=1 || Value(Flow->Snapshot(),TEXT("best_score"))!=1200) { Test->AddError(TEXT("Hello did not replace from full server counters")); return true; }
            if (!Capture.Take(TEXT("20-statistics-hello.png"))) return false; Test->AddInfo(TEXT("Actual standalone Hello variant connected/restored-or-signed-up, submitted the example score and displayed one explicit atomic statistics demo batch.")); return true;
        }
        return false;
    }
};
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FSeagullStatisticsRound,"Seagull.Acceptance.StatisticsRound",EAutomationTestFlags::ClientContext|EAutomationTestFlags::EngineFilter)
bool FSeagullStatisticsRound::RunTest(const FString&)
{
    FString Fixture; if (!FParse::Value(FCommandLine::Get(),TEXT("SeagullFixture="),Fixture)) { AddError(TEXT("Explicit loopback fixture required")); return false; }
    // A failed initial GET/restart must retain an unsent immutable draft without a clock-derived ID.
    const FString DraftKey=TEXT("draft-probe-")+FGuid::NewGuid().ToString(),User=TEXT("00000000-0000-4000-8000-000000001005");
    auto* Draft=NewObject<USeagullStatisticsIntent>(); Draft->ProjectHash=UHorizonExampleIdentity::Project(DraftKey); Draft->UserId=User; Draft->LocalIntentId=FGuid::NewGuid().ToString(EGuidFormats::DigitsWithHyphens);
    FHorizonStatisticUpdate K; K.Key=TEXT("kills"); K.Value=0; FHorizonStatisticUpdate R; R.Key=TEXT("rounds"); R.Value=1; FHorizonStatisticUpdate S; S.Key=TEXT("best_score"); S.Value=0; Draft->Updates={K,R,S};
    bool Blocked=false; bool Valid=TestTrue(TEXT("Unsent original draft persisted before any GET/operation ID"),Draft->Persist(DraftKey));
    auto* Restored=USeagullStatisticsIntent::Load(DraftKey,User,Blocked);
    Valid=TestTrue(TEXT("Restart preserves draft identity and payload with no assigned operation"),Restored && !Blocked && Restored->OperationId.IsEmpty() && Restored->SamePayload(Draft)) && Valid;
    if (Restored)
    {
        const FString Fixed=TEXT("1792123456789:10000000-0000-4000-8000-000000001005");
        Valid=TestTrue(TEXT("Clock-corrected ID finalized exactly once"),Restored->Finalize(DraftKey,Fixed)) && Valid;
        Valid=TestFalse(TEXT("Assigned original ID cannot be replaced"),Restored->Finalize(DraftKey,TEXT("1792123456790:20000000-0000-4000-8000-000000001005"))) && Valid;
        Valid=TestFalse(TEXT("Older unassigned draft cannot overwrite finalized original"),Draft->Persist(DraftKey)) && Valid;
        Valid=TestTrue(TEXT("Exact original confirmation removes only finalized batch"),Restored->Confirm(DraftKey)) && Valid;
    }
    if (UGameplayStatics::DoesSaveGameExist(USeagullStatisticsIntent::Slot(DraftKey,User),0)) UGameplayStatics::DeleteGameInSlot(USeagullStatisticsIntent::Slot(DraftKey,User),0);
    if (!Valid) return false;
    ADD_LATENT_AUTOMATION_COMMAND(SeagullStatisticsAcceptance::FRound(this)); return true;
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FSeagullHelloStatistics,"Seagull.Acceptance.HelloStatistics",EAutomationTestFlags::ClientContext|EAutomationTestFlags::EngineFilter)
bool FSeagullHelloStatistics::RunTest(const FString&)
{ FString Fixture; if (!FParse::Value(FCommandLine::Get(),TEXT("SeagullFixture="),Fixture)) { AddError(TEXT("Explicit loopback fixture required")); return false; } ADD_LATENT_AUTOMATION_COMMAND(SeagullStatisticsAcceptance::FHello(this)); return true; }
#endif
