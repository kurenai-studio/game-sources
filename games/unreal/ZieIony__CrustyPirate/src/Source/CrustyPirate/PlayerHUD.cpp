// Fill out your copyright notice in the Description page of Project Settings.


#include "PlayerHUD.h"

void UPlayerHUD::setPlayerInfo(int health, int coins, int diamonds, int keys, int swords) {
	HealthText->SetText(FText::FromString(FString::Printf(TEXT("%d"), health)));
	CoinsText->SetText(FText::FromString(FString::Printf(TEXT("%d"), coins)));
	DiamondsText->SetText(FText::FromString(FString::Printf(TEXT("%d"), diamonds)));
	KeysText->SetText(FText::FromString(FString::Printf(TEXT("%d"), keys)));
	SwordsText->SetText(FText::FromString(FString::Printf(TEXT("%d"), swords)));
}
