#include "Horizon/SeagullStatisticsSession.h"
#include "Core/SeagullGameInstance.h"
#include "Data/SeagullStatisticsIntent.h"
#include "Examples/HorizonExampleIdentity.h"
#include "HorizonSubsystem.h"
#include "Http/HorizonHttpClient.h"
#include "Managers/HorizonAuthManager.h"
#include "Managers/HorizonStatisticsManager.h"
void USeagullStatisticsSession::Initialize(USeagullGameInstance* Owner) { Instance=Owner; Sync(); }
FString USeagullStatisticsSession::CurrentContext() const
{
    auto* SDK=Instance?Instance->GetHorizonSubsystem():nullptr;
    if (!SDK || Instance->bPracticeMode || !SDK->Auth->IsSignedIn()) return TEXT("practice");
    return FString::Printf(TEXT("%llu|%llu|"),Instance->SessionGeneration,SDK->GetHttpClient()->GetRequestContextEpoch())+SDK->Auth->GetCurrentUser().UserId;
}
void USeagullStatisticsSession::Sync()
{
    const FString Next=CurrentContext(); if (Next==Context) return;
    Context=Next; ++Generation; Pending=nullptr; InFlight=nullptr; bBusy=false; Status=TEXT("Player/context changed. Refresh statistics; saved originals remain protected.");
}
bool USeagullStatisticsSession::Current(const FString& Expected,uint64 Epoch) const { return Context==Expected && CurrentContext()==Expected && Generation==Epoch; }
UHorizonSubsystem* USeagullStatisticsSession::Begin()
{
    Sync(); if (bBusy) return nullptr;
    auto* SDK=Instance?Instance->GetHorizonSubsystem():nullptr;
    if (!SDK || Instance->bPracticeMode || !SDK->Auth->IsSignedIn()) { Status=TEXT("Practice is local. Connect a player to use server statistics."); return nullptr; }
    return SDK;
}
bool USeagullStatisticsSession::IsBusy() { Sync(); return bBusy; }
bool USeagullStatisticsSession::HasPending()
{
    Sync(); auto* SDK=Instance?Instance->GetHorizonSubsystem():nullptr; if (!SDK || Instance->bPracticeMode || !SDK->Auth->IsSignedIn()) return false;
    bool Blocked; Pending=USeagullStatisticsIntent::Load(SDK->GetHttpClient()->GetApiKey(),SDK->Auth->GetCurrentUser().UserId,Blocked);
    if (Blocked) Status=TEXT("Saved original batch needs recovery. It was retained; no new batch is allowed.");
    return Blocked || Pending!=nullptr;
}
bool USeagullStatisticsSession::CanStartOnlineRound()
{
    if (IsBusy() || HasPending()) { Status=TEXT("Resolve the saved original statistics batch before another online round. Practice stays available."); return false; } return true;
}
FString USeagullStatisticsSession::GetStatus() { Sync(); return Status; }
FHorizonStatisticsSnapshot USeagullStatisticsSession::Snapshot() const
{ auto* SDK=Instance?Instance->GetHorizonSubsystem():nullptr; return SDK && !Instance->bPracticeMode && SDK->Auth->IsSignedIn()?SDK->Statistics->GetCurrentStatistics():FHorizonStatisticsSnapshot{}; }
void USeagullStatisticsSession::Refresh()
{
    auto* SDK=Begin(); if (!SDK) return; bBusy=true; const FString Sent=Context; const uint64 Epoch=Generation;
    SDK->Statistics->GetStatistics(FOnStatisticsLoaded::CreateWeakLambda(this,[this,Sent,Epoch](bool Ok,const FHorizonStatisticsSnapshot&,const FString& Code,const FString&)
    { if (!Current(Sent,Epoch)) return; bBusy=false; Status=Ok?TEXT("Server snapshot loaded. Values are never credited locally."):Code+TEXT(". Saved original retained."); }));
}
bool USeagullStatisticsSession::Compatible(const FHorizonStatisticsSnapshot& State) const
{
    for (const auto& Pair:{TPair<FString,FString>(TEXT("kills"),TEXT("sum")),TPair<FString,FString>(TEXT("rounds"),TEXT("sum")),TPair<FString,FString>(TEXT("best_score"),TEXT("max"))})
    {
        const auto* D=State.Definitions.FindByPredicate([&](const auto& V) { return V.Key==Pair.Key; });
        if (!D || D->Mode!=Pair.Value || D->Reset!=TEXT("none")) return false;
    }
    return true;
}
bool USeagullStatisticsSession::RecordRound(int64 Kills,int64 BestScore)
{
    auto* SDK=Begin(); if (!SDK || HasPending() || Kills<0 || BestScore<0 || Kills>9007199254740991LL || BestScore>9007199254740991LL) return false;
    Pending=NewObject<USeagullStatisticsIntent>(this); Pending->ProjectHash=UHorizonExampleIdentity::Project(SDK->GetHttpClient()->GetApiKey()); Pending->UserId=SDK->Auth->GetCurrentUser().UserId; Pending->LocalIntentId=FGuid::NewGuid().ToString(EGuidFormats::DigitsWithHyphens);
    FHorizonStatisticUpdate K; K.Key=TEXT("kills"); K.Value=Kills; FHorizonStatisticUpdate R; R.Key=TEXT("rounds"); R.Value=1; FHorizonStatisticUpdate S; S.Key=TEXT("best_score"); S.Value=BestScore; Pending->Updates={K,R,S};
    if (!Pending->Persist(SDK->GetHttpClient()->GetApiKey())) { Status=TEXT("Could not safely persist the original batch. Nothing sent."); return false; }
    // Snapshot lookup is read-only. The one write contains every counter from the completed round.
    RetryOriginal(); return true;
}
void USeagullStatisticsSession::RetryOriginal()
{
    auto* SDK=Begin(); if (!SDK || !HasPending() || !Pending) return;
    USeagullStatisticsIntent* Original=Pending; InFlight=Original; bBusy=true; const FString Sent=Context; const uint64 Epoch=Generation;
    SDK->Statistics->GetStatistics(FOnStatisticsLoaded::CreateWeakLambda(this,[this,SDK,Original,Sent,Epoch](bool Ok,const FHorizonStatisticsSnapshot& State,const FString& Code,const FString&)
    {
        if (!Current(Sent,Epoch)) return; bBusy=false;
        if (!Ok) { InFlight=nullptr; Status=Code+TEXT(". Original batch retained; retry only after explicit reconciliation."); return; }
        if (!Compatible(State)) { InFlight=nullptr; Status=TEXT("Configure kills=sum, rounds=sum, best_score=max with reset=none. Original batch retained; no write sent."); return; }
        // A persisted unsent draft has no server operation identity until this GET corrects the clock.
        if (Original->OperationId.IsEmpty() && !Original->Finalize(SDK->GetHttpClient()->GetApiKey(),SDK->Statistics->CreateOperationId()))
        { InFlight=nullptr; Status=TEXT("Could not finalize the saved draft after clock synchronization. No write sent."); return; }
        Send(SDK,Original);
    }));
}
void USeagullStatisticsSession::Send(UHorizonSubsystem* SDK,USeagullStatisticsIntent* Intent)
{
    const FString Project=SDK->GetHttpClient()->GetApiKey(); bool Blocked; auto* Stored=USeagullStatisticsIntent::Load(Project,SDK->Auth->GetCurrentUser().UserId,Blocked);
    if (Blocked || !Intent || !Intent->SamePayload(Stored)) { Status=TEXT("Saved batch changed or needs recovery. Nothing sent."); return; }
    InFlight=Intent; bBusy=true; const FString Sent=Context; const uint64 Epoch=Generation;
    SDK->Statistics->UpdateStatistics(Intent->Updates,Intent->OperationId,FOnStatisticsLoaded::CreateWeakLambda(this,[this,Intent,Project,Sent,Epoch](bool Ok,const FHorizonStatisticsSnapshot& State,const FString& Code,const FString&)
    {
        if (!Current(Sent,Epoch)) return; bBusy=false;
        if (Ok && State.UserId==Intent->UserId && State.OperationId==Intent->OperationId && Intent->Confirm(Project))
        { Pending=nullptr; Status=State.bReplayed?TEXT("Original batch confirmed by replay. Full server snapshot displayed."):TEXT("Round statistics accepted. Full server snapshot displayed."); }
        else Status=Code.IsEmpty()?TEXT("Receipt could not be reconciled locally. Saved original retained."):Code+TEXT(". Original batch retained; no new ID or automatic rebooking.");
        InFlight=nullptr;
    }));
}
