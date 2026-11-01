#include "Data/SeagullValueIntent.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/SecureHash.h"

FString USeagullValueIntent::Project(const FString& ApiKey) { return FMD5::HashAnsiString(*ApiKey); }
FString USeagullValueIntent::Slot(const FString& ApiKey, const FString& User) { return TEXT("seagull_values_v1_") + Project(ApiKey + TEXT("|") + User); }
bool USeagullValueIntent::IsValidFor(const FString& ApiKey, const FString& User) const
{
    FString Millis, Id; FGuid Guid; int64 Time = 0;
    return !ApiKey.IsEmpty() && !User.IsEmpty() && UserId == User && ProjectHash == Project(ApiKey)
        && OperationId.Split(TEXT(":"), &Millis, &Id) && LexTryParseString(Time, *Millis) && Time > 0 && FGuid::ParseExact(Id, EGuidFormats::DigitsWithHyphens, Guid)
        && SendCount >= 0 && (Kind == TEXT("purchase") ? !OfferKey.IsEmpty() && OfferDefinitionVersion >= 0 : Kind == TEXT("adjust") && !ValueKey.IsEmpty() && !Reason.IsEmpty() && Amount != 0 && Amount >= -9007199254740991LL && Amount <= 9007199254740991LL);
}
bool USeagullValueIntent::SamePayload(const USeagullValueIntent* Other) const
{
    return Other && Other->UserId == UserId && Other->ProjectHash == ProjectHash && Other->Kind == Kind && Other->OfferKey == OfferKey
        && Other->ValueKey == ValueKey && Other->Reason == Reason && Other->OperationId == OperationId && Other->Amount == Amount && Other->OfferDefinitionVersion == OfferDefinitionVersion;
}
USeagullValueIntent* USeagullValueIntent::Load(const FString& ApiKey, const FString& User, bool& bBlocked)
{
    bBlocked = false; FString Name = Slot(ApiKey, User);
    if (!UGameplayStatics::DoesSaveGameExist(Name, 0)) return nullptr;
    USeagullValueIntent* Saved = Cast<USeagullValueIntent>(UGameplayStatics::LoadGameFromSlot(Name, 0));
    bBlocked = !Saved || !Saved->IsValidFor(ApiKey, User);
    return bBlocked ? nullptr : Saved;
}
bool USeagullValueIntent::Persist(const FString& ApiKey) const
{
    if (!IsValidFor(ApiKey, UserId)) return false;
    bool Blocked; USeagullValueIntent* Old = Load(ApiKey, UserId, Blocked);
    if (Blocked) return false;
    // The original is immutable. A retry must never truncate its only recovery copy.
    if (Old) return SamePayload(Old);
    if (!UGameplayStatics::SaveGameToSlot(const_cast<USeagullValueIntent*>(this), Slot(ApiKey, UserId), 0)) return false;
    USeagullValueIntent* Check = Load(ApiKey, UserId, Blocked);
    return !Blocked && SamePayload(Check) && Check->SendCount == SendCount;
}
bool USeagullValueIntent::Confirm(const FString& ApiKey) const
{
    bool Blocked; USeagullValueIntent* Saved = Load(ApiKey, UserId, Blocked);
    return !Blocked && SamePayload(Saved) && UGameplayStatics::DeleteGameInSlot(Slot(ApiKey, UserId), 0)
        && !UGameplayStatics::DoesSaveGameExist(Slot(ApiKey, UserId), 0);
}
