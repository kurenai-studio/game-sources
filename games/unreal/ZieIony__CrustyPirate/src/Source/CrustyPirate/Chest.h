// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Chest.generated.h"

class UPaperFlipbookComponent;
class ACollectibleItem;
class UBoxComponent;
class UPaperFlipbook;
class USoundBase;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnChestOpened);

UCLASS()
class CRUSTYPIRATE_API AChest : public AActor
{
	GENERATED_BODY()
	
public:	
	bool locked = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UBoxComponent* BoxComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
	TObjectPtr<UPaperFlipbookComponent> Sprite;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UPaperFlipbook* UnlockedFlipbook;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	USoundBase* UnlockSound;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACollectibleItem> ContentsClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int ContentsCount = 3;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACollectibleItem> ContentsClass2;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int ContentsCount2 = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float LaunchContentsForce = 1;

	UPROPERTY(BlueprintAssignable)
	FOnChestOpened OnChestOpenedEvent;

	// Sets default values for this actor's properties
	AChest();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	void unlock();

	UFUNCTION()
	void OverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);
};
