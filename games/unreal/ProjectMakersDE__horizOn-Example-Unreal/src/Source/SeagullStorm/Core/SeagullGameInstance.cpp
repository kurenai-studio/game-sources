#include "Core/SeagullGameInstance.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Horizon/SeagullStatisticsSession.h"
#include "Data/SeagullConfigCache.h"
#include "HorizonSubsystem.h"
#include "HorizonConfig.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "SeagullStorm.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"
#include "Serialization/JsonSerializer.h"

void USeagullGameInstance::Init()
{
#if WITH_DEV_AUTOMATION_TESTS
    FString Fixture;
    if (FParse::Value(FCommandLine::Get(),TEXT("SeagullFixture="),Fixture))
    {
        const FString Prefix = TEXT("http://127.0.0.1:");
        FString Port = Fixture.RightChop(Prefix.Len()); int32 Number = 0;
        bool Digits = !Port.IsEmpty(); for (TCHAR C : Port) Digits &= C >= '0' && C <= '9';
        checkf(Fixture.StartsWith(Prefix) && Digits && LexTryParseString(Number,*Port) && Number > 0 && Number <= 65535,TEXT("Acceptance fixture must be an exact loopback HTTP endpoint"));
        UHorizonConfig* Config = GetMutableDefault<UHorizonConfig>();
        Config->Hosts = {Fixture}; Config->ApiKey = TEXT("task1004-example-fixture"); Config->MaxRetryAttempts = 1; Config->RetryDelaySeconds = .5f;
    }
#endif
    Super::Init();
	SaveData.InitDefaults();
	UE_LOG(LogSeagullStorm, Log, TEXT("SeagullGameInstance initialized"));
}

UHorizonSubsystem* USeagullGameInstance::GetHorizonSubsystem() const
{
	return GetSubsystem<UHorizonSubsystem>();
}

USeagullHorizonManager* USeagullGameInstance::GetHorizonManager()
{
	if (!HorizonManager)
	{
		HorizonManager = NewObject<USeagullHorizonManager>(this);
		HorizonManager->Initialize(GetHorizonSubsystem());
	}
	return HorizonManager;
}

USeagullConfigCache* USeagullGameInstance::GetConfigCache()
{
	if (!ConfigCache)
	{
		ConfigCache = NewObject<USeagullConfigCache>(this);
		ConfigCache->ParseFromConfigs({}); // Populate offline arrays, stats and upgrade cards.
	}
	return ConfigCache;
}

void USeagullGameInstance::BeginPractice()
{
    ++SessionGeneration;
    GetHorizonManager()->DiscardValidatedRun();
    bPracticeMode = true;
    bSaveLoaded = true;
    bCloudSaveReady = false;
    SaveOwnerId = TEXT("practice");
    SaveData.InitDefaults();
    FString Json;
    if (FFileHelper::LoadFileToString(Json, *(FPaths::ProjectSavedDir() / TEXT("SeagullStorm/practice.json"))))
    {
        TSharedPtr<FJsonObject> Object;
        if (FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Json), Object) && Object.IsValid())
            SaveData = FSeagullSaveData::FromJsonString(Json);
    }
    GetConfigCache()->ParseFromConfigs({}); // Practice always uses local defaults.
	bConfigLoaded = false;
}

void USeagullGameInstance::BeginOnlineSession(bool bKnownNewPlayer)
{
    const FString UserId = GetHorizonManager()->GetUserId();
    if (bPracticeMode || SaveOwnerId != UserId)
    {
        ++SessionGeneration;
        GetHorizonManager()->DiscardValidatedRun();
        SaveData.InitDefaults();
        bSaveLoaded = false;
        bCloudSaveReady = false;
		GetConfigCache()->ParseFromConfigs({});
		bConfigLoaded = false;
		bNewsLoaded = false;
		CachedNews.Empty();
    }
    bPracticeMode = false;
    SaveOwnerId = UserId;
	if (bKnownNewPlayer) { bSaveLoaded = true; bCloudSaveReady = true; }
}

bool USeagullGameInstance::CanMutateProgress()
{
    USeagullHorizonManager* HM = GetHorizonManager();
    return bPracticeMode || (bSaveLoaded && bCloudSaveReady && HM && HM->IsSignedIn()
        && !SaveOwnerId.IsEmpty() && SaveOwnerId == HM->GetUserId());
}

void USeagullGameInstance::PersistPracticeSave()
{
    if (!bPracticeMode) return;
    const FString Directory = FPaths::ProjectSavedDir() / TEXT("SeagullStorm");
    IFileManager::Get().MakeDirectory(*Directory, true);
    FFileHelper::SaveStringToFile(SaveData.ToJsonString(), *(Directory / TEXT("practice.json")), FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
}

USeagullStatisticsSession* USeagullGameInstance::GetStatisticsSession()
{
    if (!StatisticsSession) { StatisticsSession=NewObject<USeagullStatisticsSession>(this); StatisticsSession->Initialize(this); }
    return StatisticsSession;
}
