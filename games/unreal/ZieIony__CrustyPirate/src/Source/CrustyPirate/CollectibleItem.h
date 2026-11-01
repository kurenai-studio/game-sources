// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include <PaperFlipbookComponent.h>
#include <Components/CapsuleComponent.h>
#include <Sound/SoundBase.h>
#include "CollectibleSaveData.h"

#include "CollectibleItem.generated.h"

UENUM(BlueprintType)
enum class CollectibleType:uint8 {
	Coin,
	Diamond,
	Potion,
	DoubleJumpUpgrade,
	Key,
	Map,
	Sword
};

UCLASS()
class CRUSTYPIRATE_API ACollectibleItem : public AActor
{
	GENERATED_BODY()
	
public:	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UCapsuleComponent* CapsuleComp;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UPaperFlipbookComponent* ItemFlipbook;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	CollectibleType Type;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int Value;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	USoundBase* CollectItemSound;

	// Sets default values for this actor's properties
	ACollectibleItem();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	UFUNCTION()
	void OverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);

	static void spawn(UWorld* world, TSubclassOf<ACollectibleItem> subclass, FVector location, float launchForce);

	FCollectibleSaveData getSaveData();

	static ACollectibleItem* spawn(UWorld* world, FCollectibleSaveData& saveData);
};
