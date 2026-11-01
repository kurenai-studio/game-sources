// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "PaperTileMapActor.h"
#include "OneWayPlatform.generated.h"

/**
 * 
 */
UCLASS()
class CRUSTYPIRATE_API AOneWayPlatform : public APaperTileMapActor
{
	GENERATED_BODY()
	
public:
	AOneWayPlatform();

	virtual void Tick(float dt) override;

	void updateCollision();
};
