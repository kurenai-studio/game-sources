// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/BoxComponent.h"
#include "GameFramework/Actor.h"
#include "Interactable.generated.h"

UCLASS()
class STUCKINSIDE_API AInteractable : public AActor
{
	GENERATED_BODY()

protected:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = Camera, meta = (AllowPrivateAccess = "true"))
	UBoxComponent* InteractionHB;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = Camera, meta = (AllowPrivateAccess = "true"))
	FString Tooltip = "";
	
public:	
	// Sets default values for this actor's properties
	AInteractable();

protected:
	// Called when the game starts or when spawned
	//virtual void BeginPlay() override;

public:	
	// Called every frame
	//virtual void Tick(float DeltaTime) override;

	virtual void Interact(ACharacter* Character);

	virtual FString getToolTip(){ return Tooltip; }
};
