// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GGJ2017GameStateBase.h"
#include "GlobalEventManager.h"
#include "Components/SceneComponent.h"
#include "Metronome.generated.h"


UCLASS( Blueprintable, ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class GGJ2017_API UMetronome : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UMetronome();

	// Called when the game starts
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;

	UFUNCTION(BlueprintCallable, Category = "Beats")
	void Beat();

private:

	UGlobalEventManager* EventManager;
};
