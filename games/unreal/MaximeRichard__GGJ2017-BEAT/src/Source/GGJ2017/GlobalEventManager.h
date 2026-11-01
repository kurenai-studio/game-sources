// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "GlobalEventManager.generated.h"


UCLASS(meta = (BlueprintSpawnableComponent), Category = "Global Events")
class GGJ2017_API UGlobalEventManager : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UGlobalEventManager();

	DECLARE_DYNAMIC_MULTICAST_DELEGATE(FBeatDelegate);

	UPROPERTY(BlueprintAssignable, Category = "Level Events")
	FBeatDelegate OnBeatReceived;

	// Called when the game starts
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;

		
	
};
