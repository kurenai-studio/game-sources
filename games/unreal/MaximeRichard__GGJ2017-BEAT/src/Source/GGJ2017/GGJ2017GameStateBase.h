// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/GameStateBase.h"
#include "GlobalEventManager.h"
#include "GGJ2017GameStateBase.generated.h"

/**
 * 
 */
UCLASS()
class GGJ2017_API AGGJ2017GameStateBase : public AGameStateBase
{
	GENERATED_BODY()
	
public:

	AGGJ2017GameStateBase();

	UPROPERTY(BlueprintReadOnly, Category = "Global Events")
	UGlobalEventManager* GlobalEventHandler;
	
	
};
