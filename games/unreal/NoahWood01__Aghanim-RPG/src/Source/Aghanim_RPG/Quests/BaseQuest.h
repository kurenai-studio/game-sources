// Copyright (c) 2022 Noah Wood

#pragma once

#include "CoreMinimal.h"
#include "Aghanim_RPG/Items/DefaultItem.h"
#include "Aghanim_RPG/Enemies/BasicEnemy.h"
#include "UObject/NoExportTypes.h"
#include "BaseQuest.generated.h"

UENUM(BlueprintType)
enum class EQuestReward : uint8
{
	E_Default		UMETA(DisplayName = "DEFAULT"),
	E_Experience	UMETA(DisplayName = "EXPERIENCE"),
	E_Item			UMETA(DisplayName = "ITEM")
};

UENUM(BlueprintType)
enum class EClearCondition : uint8
{
	E_Default		UMETA(DisplayName = "DEFAULT"),
	E_Slay			UMETA(DisplayName = "SLAY"),
	E_Collect		UMETA(DisplayName = "COLLECT"),
	E_Travel		UMETA(DisplayName = "TRAVEL")
};

USTRUCT(BlueprintType)
struct FReward
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		EQuestReward rewardType;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		TSubclassOf<ADefaultItem> item;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		float experience;
};

USTRUCT(BlueprintType)
struct FObjective
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		EClearCondition clearType;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		TSubclassOf<ABasicEnemy> enemyToSlay;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		TSubclassOf<ADefaultItem> itemToCollect;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FString description;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		bool isComplete;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		int numRequired;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		int objectiveID;


};

UCLASS(BlueprintType)
class AGHANIM_RPG_API UBaseQuest : public UObject
{
	GENERATED_BODY()

	UBaseQuest();

public:
	UFUNCTION(BlueprintCallable)
		void setQuestDetails(FString _name, FString _description);

	UFUNCTION(BlueprintCallable)
		void setUpObjective(int _objectiveNum, TSubclassOf<ABasicEnemy> _enemy, TSubclassOf<ADefaultItem> _item, FString _description1, FString _description2, int _numRequired);

	UFUNCTION(BlueprintCallable)
		void setNumObjective(int _numObjectives);

	UFUNCTION(BlueprintCallable)
		void updateQuest();

	UFUNCTION(BlueprintCallable)
		void updateObjective(int _objectiveNum, int _updateValue);

	UFUNCTION(BlueprintCallable)
		void finishObjective(int _objectiveNum);

	UFUNCTION(BlueprintCallable)
		void finishQuest();

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FString name;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FString description;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FReward reward;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		TArray<FObjective> objectives;

};
