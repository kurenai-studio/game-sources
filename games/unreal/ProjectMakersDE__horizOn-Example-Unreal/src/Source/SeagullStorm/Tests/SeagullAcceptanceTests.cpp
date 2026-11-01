#if WITH_DEV_AUTOMATION_TESTS
#include "Misc/AutomationTest.h"
#include "ShaderCompiler.h"
#include "AssetCompilingManager.h"
#include "Map/SeagullMapGenerator.h"
#include "Enemies/SeagullEnemy_Boss.h"
#include "PaperSpriteComponent.h"
#include "Misc/CommandLine.h"
#include "Misc/Paths.h"
#include "Engine/Engine.h"
#include "Engine/GameViewportClient.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"
#include "Blueprint/WidgetBlueprintLibrary.h"
#include "Components/EditableTextBox.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullPlayerController.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Animation/SeagullCutoutRigComponent.h"
#include "UI/SeagullLevelUpOverlay.h"
#include "UI/SeagullPlayerValuesPanel.h"
#include "Data/SeagullValueIntent.h"
#include "HorizonSubsystem.h"
#include "Http/HorizonHttpClient.h"
#include "Managers/HorizonAuthManager.h"
#include "Managers/HorizonPlayerValuesManager.h"
#include "InputActionValue.h"

namespace SeagullAcceptance
{
struct FRun
{
    FAutomationTestBase* Test = nullptr;
    int32 Step = 0;
    double Since = FPlatformTime::Seconds();
    double Started = Since;
    FVector Before = FVector::ZeroVector;
    TWeakObjectPtr<USeagullPlayerValuesPanel> Panel;
    bool bAuthDone = false, bAuthOk = false, bCapturing = false, bBossPositioned = false;
    void Next() { Step++; Since = FPlatformTime::Seconds(); }
    bool Capture(const TCHAR* Name)
    {
        if (FParse::Param(FCommandLine::Get(),TEXT("nullrhi"))) return true;
        if (GShaderCompilingManager && GShaderCompilingManager->IsCompiling()) return false;
        if (!bCapturing) { FString Directory; FParse::Value(FCommandLine::Get(),TEXT("SeagullCaptureDir="),Directory);
            FScreenshotRequest::RequestScreenshot((Directory.IsEmpty()?FPaths::ProjectDir()/TEXT("screenshots/task1004"):Directory)/Name,true,false); bCapturing=true; return false; }
        if (FScreenshotRequest::IsScreenshotRequested()) return false;
        bCapturing=false; return true;
    }
};
static void Invoke(UObject* Object,const TCHAR* Name)
{ if (Object) if (UFunction* Function = Object->FindFunction(FName(Name))) Object->ProcessEvent(Function,nullptr); }
static int64 Balance(UHorizonSubsystem* SDK,const TCHAR* Key)
{ for (const auto& V : SDK->PlayerValues->GetCurrentState().Values) if (V.Key==Key) return V.Balance; return MIN_int64; }
class FSmoke : public IAutomationLatentCommand
{
    TSharedRef<FRun> Run;
public:
    explicit FSmoke(TSharedRef<FRun> InRun):Run(InRun) {}
    virtual bool Update() override
    {
        if (FPlatformTime::Seconds()-Run->Started>90) { Run->Test->AddError(FString::Printf(TEXT("Acceptance timeout at step%d"),Run->Step)); return true; }
        UWorld* World = nullptr;
        for (const FWorldContext& C : GEngine->GetWorldContexts()) if (C.World() && C.World()->IsGameWorld()) { World=C.World(); break; }
        if (!World) return false;
        auto* GI = Cast<USeagullGameInstance>(World->GetGameInstance()); auto* GM = Cast<ASeagullStormGameMode>(World->GetAuthGameMode());
        auto* GS = World->GetGameState<ASeagullStormGameState>(); auto* PC = Cast<ASeagullPlayerController>(UGameplayStatics::GetPlayerController(World,0));
        if (!GI || !GM || !GS || !PC) return false;
        auto* SDK = GI->GetHorizonSubsystem(); double Elapsed=FPlatformTime::Seconds()-Run->Since;
        auto Fail=[&](const FString& Error) { Run->Test->AddError(Error); return true; };
        switch (Run->Step)
        {
        case 0:
            if (Elapsed<1) return false;
            FAssetCompilingManager::Get().FinishAllCompilation();
            if (GM->GetCurrentScreen()!=ESeagullGameScreen::Title) return Fail(TEXT("Fresh isolated run must show Title"));
            if (!Run->Capture(TEXT("01-title.png"))) return false; Run->Next(); break;
        case 1:
            if (Elapsed<1) return false; GI->BeginPractice(); GM->SwitchToScreen(ESeagullGameScreen::Hub); Run->Next(); break;
        case 2:
            if (Elapsed<1) return false;
            if (!Run->Capture(TEXT("02-practice-hub.png"))) return false; Run->Panel=CreateWidget<USeagullPlayerValuesPanel>(PC); Run->Panel->AddToViewport(100); Invoke(Run->Panel.Get(),TEXT("OnState")); Run->Next(); break;
        case 3:
            if (Elapsed<1) return false; if (!Run->Capture(TEXT("03-values-offline-guard.png"))) return false;
            if (SDK->PlayerValues->GetCurrentState().bPresent) return Fail(TEXT("Practice must not initialize server balances"));
            Run->Panel->RemoveFromParent(); GM->StartRun(); Run->Next(); break;
        case 4:
            if (Elapsed<1) return false;
            for (TActorIterator<ASeagullMapGenerator> I(World); I; ++I)
            {
                TArray<UPaperSpriteComponent*> Sprites; I->GetComponents(Sprites);
                if (Sprites.IsEmpty()) return Fail(TEXT("Imported arena sprite missing"));
                for (auto* Sprite:Sprites) if (FMath::Abs(Sprite->GetForwardVector().Z)>.01 || FMath::Abs(Sprite->GetUpVector().Z)>.01) return Fail(TEXT("Arena sprite is vertical instead of lying on X/Y"));
            }
            if (auto* Pawn=Cast<ASeagullPlayerPawn>(PC->GetPawn()))
            { if (!Pawn->CutoutRig->IsReady()) return Fail(TEXT("Imported gull cutout rig missing")); Run->Before=Pawn->GetActorLocation(); }
            else return Fail(TEXT("Run pawn missing"));
            PC->OnMoveInput(FInputActionValue(FVector2D(1,0))); Run->Next(); break;
        case 5:
            if (Elapsed<.8) return false;
            if (!PC->GetPawn() || FVector::Dist2D(Run->Before,PC->GetPawn()->GetActorLocation())<10) return Fail(TEXT("Native player movement did not advance"));
            PC->OnMoveInput(FInputActionValue(FVector2D::ZeroVector)); if (!Run->Capture(TEXT("04-gameplay-cutout.png"))) return false; PC->TogglePause(); Run->Next(); break;
        case 6:
            if (Elapsed<1) return false;
            if (!UGameplayStatics::IsGamePaused(World)) return Fail(TEXT("Pause failed"));
            if (!Run->Capture(TEXT("05-pause.png"))) return false; PC->TogglePause(); GS->AddXP(GS->XPToNextLevel); Run->Next(); break;
        case 7:
            if (Elapsed<1) return false;
            if (GS->PendingLevelUpChoices<1) return Fail(TEXT("XP did not create a choice"));
            if (!Run->Capture(TEXT("06-level-up.png"))) return false;
            { TArray<UUserWidget*> Widgets; UWidgetBlueprintLibrary::GetAllWidgetsOfClass(World,Widgets,USeagullLevelUpOverlay::StaticClass());
              for (auto* Widget:Widgets) if (Widget->IsInViewport()) Invoke(Widget,TEXT("OnChoice1")); }
            Run->Next(); break;
        case 8:
            if (Elapsed<1) return false;
            if (GS->PendingLevelUpChoices!=0 || UGameplayStatics::IsGamePaused(World)) return Fail(TEXT("Choice did not resume exactly once"));
            CastChecked<ASeagullPlayerPawn>(PC->GetPawn())->HealthComponent->TakeDamage(10000); Run->Next(); break;
        case 9:
            if (Elapsed<1) return false;
            if (GM->GetCurrentScreen()!=ESeagullGameScreen::GameOver) return Fail(TEXT("Death did not show game over"));
            if (!Run->Capture(TEXT("07-game-over.png"))) return false; GM->ReturnToHub(); GM->StartRun(); Run->Next(); break;
        case 10:
            if (Elapsed<1) return false;
            if (!PC->GetPawn() || !GS->bRunActive) return Fail(TEXT("Restart did not create a fresh run"));
            GS->TickTimer(GS->TimeRemaining); Run->Next(); break;
        case 11:
            if (!GS->bBossSpawned || Elapsed<1) return false;
            { TActorIterator<ASeagullEnemy_Boss> Boss(World);
              if (!Boss) return Fail(TEXT("Survival timer did not spawn the octopus"));
              // Keep the spawned actor visible for the deterministic render proof.
              if (!Run->bBossPositioned) { Boss->SetActorLocation(PC->GetPawn()->GetActorLocation()+FVector(120,0,0)); Run->bBossPositioned=true; return false; }
              if (!Run->Capture(TEXT("13-boss.png"))) return false;
              Boss->TakeDamageAmount(100000); }
            Run->Next(); break;
        case 12:
            if (Elapsed<1) return false;
            if (GS->bRunActive || GM->GetCurrentScreen()!=ESeagullGameScreen::GameOver) return Fail(TEXT("Boss defeat did not finish the run"));
            if (!Run->Capture(TEXT("14-victory.png"))) return false;
            GM->SwitchToScreen(ESeagullGameScreen::Title);
            SDK->Auth->SignUpAnonymous(TEXT("Task1004Fixture"),FOnAuthComplete::CreateLambda([R=Run](bool Ok){R->bAuthDone=true;R->bAuthOk=Ok;})); Run->Next(); break;
        case 13:
            if (!Run->bAuthDone) return false; if (!Run->bAuthOk) return Fail(TEXT("Synthetic loopback auth failed"));
            GI->BeginOnlineSession(true); Run->Panel=CreateWidget<USeagullPlayerValuesPanel>(PC); Run->Panel->AddToViewport(100); Invoke(Run->Panel.Get(),TEXT("OnState")); Run->Next(); break;
        case 14:
            if (!SDK->PlayerValues->GetCurrentState().bPresent) return false;
            CastChecked<UEditableTextBox>(Run->Panel->GetWidgetFromName(TEXT("ValuesOfferKey")))->SetText(FText::FromString(TEXT("energy-pack")));
            Invoke(Run->Panel.Get(),TEXT("OnOffers")); Run->Next(); break;
        case 15:
            if (!SDK->PlayerValues->GetCurrentOffers().bPresent) return false;
            if (!Run->Capture(TEXT("08-online-balances-offers.png"))) return false; Invoke(Run->Panel.Get(),TEXT("OnPurchase")); Run->Next(); break;
        case 16:
            if (SDK->PlayerValues->GetCurrentOffers().DefinitionVersion!=2 || Elapsed<1) return false;
            { bool Blocked; if (USeagullValueIntent::Load(SDK->GetHttpClient()->GetApiKey(),SDK->Auth->GetCurrentUser().UserId,Blocked) || Blocked) return Fail(TEXT("Price change must not create an operation")); }
            if (!Run->Capture(TEXT("09-changed-price-confirmation.png"))) return false; Invoke(Run->Panel.Get(),TEXT("OnPurchase")); Run->Next(); break;
        case 17:
            if (SDK->PlayerValues->LastErrorCode!=TEXT("TEMPORARY") || Elapsed<2) return false;
            { bool Blocked; auto* Intent=USeagullValueIntent::Load(SDK->GetHttpClient()->GetApiKey(),SDK->Auth->GetCurrentUser().UserId,Blocked);
              if (!Intent || Blocked) return Fail(TEXT("Lost response did not retain original operation"));
              const auto Project=SDK->GetHttpClient()->GetApiKey(); Intent->SendCount++;
              if (!Intent->Persist(Project)) return Fail(TEXT("Retry did not preserve matching original"));
              auto* Original=USeagullValueIntent::Load(Project,Intent->UserId,Blocked);
              if (!Original || Blocked || Original->SendCount!=1) return Fail(TEXT("Retry overwrote immutable original file"));
              Intent->OfferKey=TEXT("different-payload");
              if (Intent->Persist(Project)) return Fail(TEXT("A conflicting payload replaced the original")); }
            if (!Run->Capture(TEXT("10-uncertain-original-retained.png"))) return false; Invoke(Run->Panel.Get(),TEXT("OnRetry")); Run->Next(); break;
        case 18:
            if (SDK->PlayerValues->GetCurrentOffers().DefinitionVersion!=3 || Elapsed<1) return false;
            { bool Blocked; auto* Intent=USeagullValueIntent::Load(SDK->GetHttpClient()->GetApiKey(),SDK->Auth->GetCurrentUser().UserId,Blocked);
              if (!Intent || Blocked || Intent->SendCount!=1 || Intent->OfferDefinitionVersion!=2) return Fail(TEXT("Retry repricing changed the original intent")); }
            if (!Run->Capture(TEXT("16-retry-price-confirmation.png"))) return false;
            Invoke(Run->Panel.Get(),TEXT("OnRetry")); Run->Next(); break;
        case 19:
            if (Balance(SDK,TEXT("energy"))!=10 || !SDK->PlayerValues->GetCurrentState().Operation.bReplayed) return false;
            if (Balance(SDK,TEXT("gold"))!=93) return Fail(TEXT("Replay charged or credited twice"));
            if (!Run->Capture(TEXT("11-original-replay.png"))) return false;
            CastChecked<UEditableTextBox>(Run->Panel->GetWidgetFromName(TEXT("ValuesAdjustKey")))->SetText(FText::FromString(TEXT("energy")));
            CastChecked<UEditableTextBox>(Run->Panel->GetWidgetFromName(TEXT("ValuesAdjustAmount")))->SetText(FText::FromString(TEXT("-1")));
            Invoke(Run->Panel.Get(),TEXT("OnAdjust")); Run->Next(); break;
        case 20:
            if (Balance(SDK,TEXT("energy"))!=9 || Elapsed<1) return false;
            { bool Blocked; if (USeagullValueIntent::Load(SDK->GetHttpClient()->GetApiKey(),SDK->Auth->GetCurrentUser().UserId,Blocked) || Blocked) return Fail(TEXT("Confirmed original operation not removed")); }
            if (!Run->Capture(TEXT("12-adjustment.png"))) return false; Run->Next(); break;
        case 21:
            if (Elapsed<1) return false;
            Run->Panel->RemoveFromParent(); SDK->Auth->SignOut(); Run->Test->AddInfo(TEXT("Native title/practice/movement/cutout/pause/choice/death/restart/boss victory and real loopback auth/offers/price confirmation/uncertain retry/replay/adjust paths passed.")); return true;
        }
        return false;
    }
};
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FSeagullNativeAcceptance,"Seagull.Acceptance.GameAndPlayerValues",EAutomationTestFlags::ClientContext|EAutomationTestFlags::EngineFilter)
bool FSeagullNativeAcceptance::RunTest(const FString&)
{
    FString Fixture; if (!FParse::Value(FCommandLine::Get(),TEXT("SeagullFixture="),Fixture)) { AddError(TEXT("Pass an explicit loopback SeagullFixture before running native acceptance")); return false; }
    auto Run=MakeShared<SeagullAcceptance::FRun>(); Run->Test=this;
    ADD_LATENT_AUTOMATION_COMMAND(SeagullAcceptance::FSmoke(Run)); return true;
}
#endif
