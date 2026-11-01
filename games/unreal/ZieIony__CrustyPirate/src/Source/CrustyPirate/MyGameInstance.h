// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include <vector>

#include "MyGameInstance.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_FiveParams(FOnPlayerInfoChanged, int, Health, int, Coins, int, Diamonds, int, Keys, int, Swords);

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnLevelFinished);

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API UMyGameInstance : public UGameInstance
{
	GENERATED_BODY()

	static inline FString SAVE_SLOT_NAME = FString("default");
	static inline int SAVE_SLOT_INDEX = 0;

	static inline std::vector<FString> levels = {
		FString(TEXT("Level_1")),
		FString(TEXT("Level_2")),
		FString(TEXT("Level_3")),
		FString(TEXT("Level_4")),
		FString(TEXT("Level_5"))
	};
	
public:
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int PlayerHP = 100;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int CoinsCollected = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int DiamondsCollected = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	bool IsDoubleJumpUnlocked = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int CurrentLevelIndex = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int MapsCollected = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int KeysOwned = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	int SwordsOwned = 0;

	UPROPERTY(BlueprintAssignable)
	FOnPlayerInfoChanged OnPlayerInfoChangedEvent;

	UPROPERTY(BlueprintAssignable)
	FOnLevelFinished OnLevelFinishedEvent;

	void fireOnPlayerInfoChanged();

	void setPlayerHP(int newHP);

	void collectCoins(int count);

	void collectDiamonds(int count);

	void collectKey();

	void useKey();
	
	void collectSwords(int count);

	void useSword();

	void finishLevel();

	UFUNCTION(BlueprintCallable)
	void nextLevel();

	void collectMap();

	UFUNCTION(BlueprintCallable)
	void restartGame();

	UFUNCTION(BlueprintCallable)
	void saveGame(bool async);

	UFUNCTION(BlueprintCallable)
	void loadGame();
};
