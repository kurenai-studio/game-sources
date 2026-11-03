// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Components/StaticMeshComponent.h"
#include "PaperSpriteComponent.h"
#include "CellClass.generated.h"

UCLASS()
class CAVEAUTOMATA_API ACellClass : public AActor
{
	GENERATED_BODY()
	
public:	
	UPROPERTY(EditAnywhere, Category = "Sprite Component")
		class UPaperSpriteComponent* Sprite;

	UPROPERTY(EditAnywhere, Category = "Cell Info")
		FVector2D info;

	bool lifeState;

	bool clickStatus = false;

	int changedCellCounter = 0;

	// Sets default values for this actor's properties
	ACellClass();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

private:

	UStaticMeshComponent* CollisionMesh = nullptr;

	UFUNCTION()
		void OnGetClicked(AActor* Target, FKey ButtonPressed);

	UFUNCTION()
		void OnMouseRelease(AActor* Target, FKey ButtonPressed);
};
