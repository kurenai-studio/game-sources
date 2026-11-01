// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/StaticMeshActor.h"
#include "WallRunnableInterface.h"
#include "WallRunnableStaticMeshActor.generated.h"

/**
 * 
 */
UCLASS()
class OBSTACLEASSAULT_API AWallRunnableStaticMeshActor : public AStaticMeshActor, public IWallRunnableInterface
{
	GENERATED_BODY()
	
};
