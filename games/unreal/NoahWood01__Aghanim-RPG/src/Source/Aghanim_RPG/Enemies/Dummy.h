// Copyright (c) 2022 Noah Wood

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Dummy.generated.h"

UCLASS()
class AGHANIM_RPG_API ADummy : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ADummy();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	// basic stats for enemy
	UFUNCTION(BlueprintCallable)
		void takeDamage(float damageAmount);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Enemy)
		float health;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Enemy)
		float maxHealth;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

};
