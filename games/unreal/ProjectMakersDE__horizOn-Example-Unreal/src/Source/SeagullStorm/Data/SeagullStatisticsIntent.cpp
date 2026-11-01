#include "Data/SeagullStatisticsIntent.h"
#include "Examples/HorizonExampleIdentity.h"
#include "Transport/HorizonStatisticsTransportContract.h"
#include "Kismet/GameplayStatics.h"
FString USeagullStatisticsIntent::Slot(const FString& Key,const FString& User) { return TEXT("seagull_statistics_v1_")+UHorizonExampleIdentity::Project(Key+TEXT("|")+User); }
bool USeagullStatisticsIntent::IsValidFor(const FString& Key,const FString& User) const
{
    FGuid Id,Local;
    if (Key.IsEmpty() || UserId!=User || !FGuid::ParseExact(User,EGuidFormats::DigitsWithHyphens,Id) || ProjectHash!=UHorizonExampleIdentity::Project(Key) ||
        !FGuid::ParseExact(LocalIntentId,EGuidFormats::DigitsWithHyphens,Local) || (!OperationId.IsEmpty() && !HorizonTransportContract::IsStatisticsOperationId(TCHAR_TO_UTF8(*OperationId))) || Updates.Num()!=3) return false;
    return Updates[0].Key==TEXT("kills") && Updates[1].Key==TEXT("rounds") && Updates[2].Key==TEXT("best_score") && Updates[1].Value==1 &&
        Updates[0].Value>=0 && Updates[0].Value<=9007199254740991LL && Updates[2].Value>=0 && Updates[2].Value<=9007199254740991LL;
}
bool USeagullStatisticsIntent::SamePayload(const USeagullStatisticsIntent* Other) const
{
    if (!Other || ProjectHash!=Other->ProjectHash || UserId!=Other->UserId || OperationId!=Other->OperationId || LocalIntentId!=Other->LocalIntentId || Updates.Num()!=Other->Updates.Num()) return false;
    for (int32 I=0;I<Updates.Num();++I) if (Updates[I].Key!=Other->Updates[I].Key || Updates[I].Value!=Other->Updates[I].Value) return false;
    return true;
}
USeagullStatisticsIntent* USeagullStatisticsIntent::Load(const FString& Key,const FString& User,bool& Blocked)
{
    Blocked=false; if (!UGameplayStatics::DoesSaveGameExist(Slot(Key,User),0)) return nullptr;
    auto* P=Cast<USeagullStatisticsIntent>(UGameplayStatics::LoadGameFromSlot(Slot(Key,User),0)); Blocked=!P || !P->IsValidFor(Key,User); return Blocked?nullptr:P;
}
bool USeagullStatisticsIntent::Persist(const FString& Key) const
{
    if (!IsValidFor(Key,UserId)) return false;
    bool Blocked; auto* Existing=Load(Key,UserId,Blocked); if (Blocked) return false; if (Existing) return SamePayload(Existing);
    if (!UGameplayStatics::SaveGameToSlot(const_cast<USeagullStatisticsIntent*>(this),Slot(Key,UserId),0)) return false;
    auto* Check=Load(Key,UserId,Blocked); return !Blocked && SamePayload(Check);
}
bool USeagullStatisticsIntent::Confirm(const FString& Key) const
{
    if (OperationId.IsEmpty()) return false;
    bool Blocked; auto* Existing=Load(Key,UserId,Blocked);
    return !Blocked && SamePayload(Existing) && UGameplayStatics::DeleteGameInSlot(Slot(Key,UserId),0) && !UGameplayStatics::DoesSaveGameExist(Slot(Key,UserId),0);
}

bool USeagullStatisticsIntent::Finalize(const FString& Key,const FString& NewId)
{
    if (!OperationId.IsEmpty() || !HorizonTransportContract::IsStatisticsOperationId(TCHAR_TO_UTF8(*NewId))) return false;
    bool Blocked; auto* Stored=Load(Key,UserId,Blocked); if (Blocked || !SamePayload(Stored)) return false;
    OperationId=NewId;
    if (!UGameplayStatics::SaveGameToSlot(this,Slot(Key,UserId),0)) return false;
    return SamePayload(Load(Key,UserId,Blocked)) && !Blocked;
}
