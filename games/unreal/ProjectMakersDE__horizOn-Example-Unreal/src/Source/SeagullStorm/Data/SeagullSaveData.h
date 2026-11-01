#pragma once

#include "CoreMinimal.h"
#include "SeagullSaveData.generated.h"

USTRUCT(BlueprintType)
struct FSeagullSaveData
{
	GENERATED_BODY()

	UPROPERTY()
	int32 Coins = 0;

	UPROPERTY()
	int32 Highscore = 0;

	UPROPERTY()
	int32 TotalRuns = 0;

	UPROPERTY()
	TMap<FString, int32> Upgrades;

	UPROPERTY()
	TArray<FString> GiftCodesRedeemed;

	FString ToJsonString() const;
	static FSeagullSaveData FromJsonString(const FString& Json);

	void InitDefaults()
	{
		Coins = 0;
		Highscore = 0;
		TotalRuns = 0;
		Upgrades.Empty();
		Upgrades.Add(TEXT("speed"), 0);
		Upgrades.Add(TEXT("damage"), 0);
		Upgrades.Add(TEXT("hp"), 0);
		Upgrades.Add(TEXT("magnet"), 0);
		GiftCodesRedeemed.Empty();
	}

	int32 GetUpgradeLevel(const FString& Key) const
	{
		const int32* Found = Upgrades.Find(Key);
		return Found ? *Found : 0;
	}
};
