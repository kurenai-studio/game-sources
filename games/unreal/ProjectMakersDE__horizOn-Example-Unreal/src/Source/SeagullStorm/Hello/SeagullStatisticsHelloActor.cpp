#include "Hello/SeagullStatisticsHelloActor.h"
#include "Core/SeagullGameInstance.h"
#include "Horizon/SeagullHorizonManager.h"
#include "UI/SeagullStatisticsPanel.h"
#include "HorizonSubsystem.h"
#include "HorizonSessionSave.h"
#include "Examples/HorizonExampleIdentity.h"
#include "Managers/HorizonAuthManager.h"
#include "Managers/HorizonLeaderboardManager.h"
#include "Kismet/GameplayStatics.h"
void ASeagullStatisticsHelloActor::BeginPlay()
{
    Super::BeginPlay(); auto* GI=Cast<USeagullGameInstance>(GetGameInstance()); if (!GI) return;
    auto* SDK=GI->GetHorizonSubsystem(); SDK->OnConnected.AddUniqueDynamic(this,&ASeagullStatisticsHelloActor::Connected);
    if (SDK->IsConnected()) Connected(); else GI->GetHorizonManager()->ConnectToServer();
}
void ASeagullStatisticsHelloActor::Connected()
{
    if (bAuthStarted) return; bAuthStarted=true;
    auto* GI=Cast<USeagullGameInstance>(GetGameInstance()); if (!GI) return; auto* HM=GI->GetHorizonManager();
    if (HM->IsSignedIn()) { Authenticated(true,true); return; }
    const bool Restored=UHorizonExampleIdentity::ShouldRestoreSession(GI->GetHorizonSubsystem());
    auto Callback=[Weak=TWeakObjectPtr<ASeagullStatisticsHelloActor>(this),Restored](bool Ok) { if (auto* Self=Weak.Get()) Self->Authenticated(Ok,Restored); };
    if (Restored) HM->RestoreSession(Callback,true); else HM->SignUpAnonymous(TEXT("StatisticsHello"),Callback);
}
void ASeagullStatisticsHelloActor::Authenticated(bool Success,bool Restored)
{
    auto* GI=Cast<USeagullGameInstance>(GetGameInstance()); if (!GI || !Success) { UE_LOG(LogTemp,Warning,TEXT("[StatisticsHello] Authentication/recovery failed. No replacement identity or batch created.")); return; }
    GI->BeginOnlineSession(!Restored); auto* PC=UGameplayStatics::GetPlayerController(GetWorld(),0); if (!PC) return;
    Panel=CreateWidget<USeagullStatisticsPanel>(PC); Panel->EnableHelloDemo(); Panel->AddToViewport(100);
    PC->bShowMouseCursor=true; FInputModeUIOnly Mode; PC->SetInputMode(Mode);
    // Match the original Hello's one example score, then leave statistics to explicit UI actions.
    GI->GetHorizonSubsystem()->Leaderboard->SubmitScore(1000,FOnRequestComplete::CreateWeakLambda(this,[](bool Ok,const FString&)
    { UE_LOG(LogTemp,Log,TEXT("[StatisticsHello] Ready: connected session, score example %s, explicit statistics buttons."),Ok?TEXT("submitted"):TEXT("unavailable")); }));
}
