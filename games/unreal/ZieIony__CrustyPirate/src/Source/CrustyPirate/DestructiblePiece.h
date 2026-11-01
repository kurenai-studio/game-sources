// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include <GameFramework/Actor.h>
#include <Components/CapsuleComponent.h>
#include "DestructiblePiece.generated.h"

class UBoxComponent;
class UPaperSpriteComponent;

UCLASS()
class CRUSTYPIRATE_API ADestructiblePiece : public AActor
{
	GENERATED_BODY()
	
public:	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UBoxComponent* BoxComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UPaperSpriteComponent* Sprite;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FVector LaunchOffset;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float LaunchForce = 3000;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float DestroyDelay = 3;

	FTimerHandle destroyTimer;

	// Sets default values for this actor's properties
	ADestructiblePiece();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	void onDestroyTimerTimeout();
};
