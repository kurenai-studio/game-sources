// Copyright (c) 2022 Noah Wood

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "DefaultItem.generated.h"

UCLASS()
class AGHANIM_RPG_API ADefaultItem : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ADefaultItem();

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		float weight;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
		FString name;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

};
