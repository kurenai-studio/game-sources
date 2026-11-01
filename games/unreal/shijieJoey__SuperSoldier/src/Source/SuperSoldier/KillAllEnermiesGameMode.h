// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "SuperSoldierGameModeBase.h"
#include "KillAllEnermiesGameMode.generated.h"

/**
 * 
 */
UCLASS()
class SUPERSOLDIER_API AKillAllEnermiesGameMode : public ASuperSoldierGameModeBase
{
	GENERATED_BODY()
	
public:
	virtual void PawnKilled(APawn* PawnKilled) override;

private:
	void EndGame(bool bPlayerWin);
};
