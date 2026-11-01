// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/Actor.h"
#include "PlayerPawn.h"
#include "EnemyProjecile.generated.h"

UCLASS()
class GGJ2017_API AEnemyProjecile : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AEnemyProjecile();

	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void Tick( float DeltaSeconds ) override;

	UFUNCTION(BlueprintCallable, Category = "Collisions")
	void OnCollision(ECollisionChannel other, AActor* actor);
	
};
