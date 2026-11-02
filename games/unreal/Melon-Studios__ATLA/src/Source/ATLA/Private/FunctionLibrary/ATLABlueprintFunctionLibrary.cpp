// Copyright Melon Studios.

#include "FunctionLibrary/ATLABlueprintFunctionLibrary.h"

#include "ATLAGameInstance.h"
#include "Kismet/GameplayStatics.h"

UATLAGameInstance* UATLABlueprintFunctionLibrary::GetATLAGameInstance(const UObject* WorldContextObject)
{
	return Cast<UATLAGameInstance>(UGameplayStatics::GetGameInstance(WorldContextObject));
}

FString UATLABlueprintFunctionLibrary::GetGameInfoDetails()
{
	FString GameName;
	GConfig->GetString(TEXT("/Script/EngineSettings.GeneralProjectSettings"), TEXT("ProjectName"), GameName, GGameIni);

	FString GameVersion;
	GConfig->GetString(TEXT("/Script/EngineSettings.GeneralProjectSettings"), TEXT("ProjectVersion"), GameVersion, GGameIni);

	FString CompanyName;
	GConfig->GetString(TEXT("/Script/EngineSettings.GeneralProjectSettings"), TEXT("CompanyName"), CompanyName, GGameIni);

	return CompanyName + "-" + GameName + "-v" + GameVersion;
}
