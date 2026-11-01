// Fill out your copyright notice in the Description page of Project Settings.


#include "MyGameInstance.h"
#include <Kismet/GameplayStatics.h>
#include "PirateSaveGame.h"
#include "Captain.h"
#include "Enemy.h"
#include "CollectibleItem.h"
#include "Helpers.h"

void UMyGameInstance::fireOnPlayerInfoChanged() {
	OnPlayerInfoChangedEvent.Broadcast(PlayerHP, CoinsCollected, DiamondsCollected, KeysOwned, SwordsOwned);
}

void UMyGameInstance::setPlayerHP(int newHP) {
	PlayerHP = newHP;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::collectCoins(int count) {
	CoinsCollected += count;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::collectDiamonds(int count) {
	DiamondsCollected += count;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::collectKey() {
	KeysOwned++;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::useKey() {
	KeysOwned--;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::collectSwords(int count) {
	SwordsOwned += count;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::useSword() {
	SwordsOwned--;
	fireOnPlayerInfoChanged();
}

void UMyGameInstance::finishLevel() {
	OnLevelFinishedEvent.Broadcast();
}

void UMyGameInstance::nextLevel() {
	CurrentLevelIndex++;
	KeysOwned = 0;
	SwordsOwned = 0;
	UGameplayStatics::OpenLevel(GetWorld(), FName(levels[CurrentLevelIndex]));
}

void UMyGameInstance::collectMap() {
	MapsCollected++;
}

void UMyGameInstance::restartGame() {
	PlayerHP = 100;
	CoinsCollected = 0;
	DiamondsCollected = 0;
	MapsCollected = 0;
	IsDoubleJumpUnlocked = false;
	KeysOwned = 0;
	SwordsOwned = 0;

	fireOnPlayerInfoChanged();

	CurrentLevelIndex = 0;
	UGameplayStatics::OpenLevel(GetWorld(), FName(levels[CurrentLevelIndex]));
}

void UMyGameInstance::saveGame(bool async) {
	UPirateSaveGame* saveData = (UPirateSaveGame*)UGameplayStatics::CreateSaveGameObject(UPirateSaveGame::StaticClass());

	TArray<AActor*> captainActors;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), ACaptain::StaticClass(), captainActors);
	saveData->gameSaveData.captainData = ((ACaptain*)captainActors[0])->getSaveData();

	// save enemies
	saveData->gameSaveData.enemyData.Reset(saveData->gameSaveData.enemyData.Num());
	TArray<AActor*> enemyActors;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), AEnemy::StaticClass(), enemyActors);
	for (auto actor : enemyActors) {
		AEnemy* enemy = (AEnemy*)actor;
		saveData->gameSaveData.enemyData.Add(enemy->getSaveData());
	}

	// save collectibles
	saveData->gameSaveData.collectibleData.Reset(saveData->gameSaveData.collectibleData.Num());
	TArray<AActor*> collectibleActors;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), ACollectibleItem::StaticClass(), collectibleActors);
	for (auto actor : collectibleActors) {
		ACollectibleItem* collectible = (ACollectibleItem*)actor;
		saveData->gameSaveData.collectibleData.Add(collectible->getSaveData());
	}

	saveData->gameSaveData.CurrentLevelIndex = CurrentLevelIndex;
	saveData->gameSaveData.CoinsCollected = CoinsCollected;
	saveData->gameSaveData.DiamondsCollected = DiamondsCollected;
	saveData->gameSaveData.PlayerHP = PlayerHP;
	saveData->gameSaveData.IsDoubleJumpUnlocked = IsDoubleJumpUnlocked;
	saveData->gameSaveData.KeysOwned = KeysOwned;
	saveData->gameSaveData.MapsCollected = MapsCollected;
	saveData->gameSaveData.SwordsOwned = SwordsOwned;

	if (async) {
		FAsyncSaveGameToSlotDelegate OnGameSaved;
		UGameplayStatics::AsyncSaveGameToSlot(saveData, SAVE_SLOT_NAME, SAVE_SLOT_INDEX, OnGameSaved);
	} else {
		UGameplayStatics::SaveGameToSlot(saveData, SAVE_SLOT_NAME, SAVE_SLOT_INDEX);
	}
}

void UMyGameInstance::loadGame() {
	if (!UGameplayStatics::DoesSaveGameExist(SAVE_SLOT_NAME, SAVE_SLOT_INDEX)) {
		restartGame();
		return;
	}
	UPirateSaveGame* pirateSaveData = (UPirateSaveGame*)UGameplayStatics::LoadGameFromSlot(SAVE_SLOT_NAME, SAVE_SLOT_INDEX);
	auto& gameSaveData = pirateSaveData->gameSaveData;

	TArray<AActor*> captainActors;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), ACaptain::StaticClass(), captainActors);
	((ACaptain*)captainActors[0])->setSaveData(gameSaveData.captainData);

	// restore enemies
	DestroyAllActorsOfClass<AEnemy>(GetWorld());
	for(auto& saveData : gameSaveData.enemyData){
		AEnemy::spawn(GetWorld(), saveData);
	}

	// restore collectibles
	DestroyAllActorsOfClass<ACollectibleItem>(GetWorld());
	for (auto& saveData : gameSaveData.collectibleData) {
		ACollectibleItem::spawn(GetWorld(), saveData);
	}

	CurrentLevelIndex = gameSaveData.CurrentLevelIndex;
	CoinsCollected = gameSaveData.CoinsCollected;
	DiamondsCollected = gameSaveData.DiamondsCollected;
	PlayerHP = gameSaveData.PlayerHP;
	IsDoubleJumpUnlocked = gameSaveData.IsDoubleJumpUnlocked;
	KeysOwned = gameSaveData.KeysOwned;
	MapsCollected = gameSaveData.MapsCollected;
	SwordsOwned = gameSaveData.SwordsOwned;
	fireOnPlayerInfoChanged();

	if (pirateSaveData->gameSaveData.CurrentLevelIndex != CurrentLevelIndex) {
		UGameplayStatics::OpenLevel(GetWorld(), FName(levels[CurrentLevelIndex]));
	}
}
