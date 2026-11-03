// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Interactable.h"
#include "StuckInsideGS.h"
#include "WindowShutters.generated.h"

/**
 * 
 */
UCLASS()
class STUCKINSIDE_API AWindowShutters : public AInteractable
{
	GENERATED_BODY()
	
	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess),BlueprintReadOnly)
	USkeletalMeshComponent* Doors;
	
	UPROPERTY(Replicated,ReplicatedUsing=onDoorChanged)
	bool isOpened = true;

	virtual void Interact(ACharacter* Character) override;

	UFUNCTION(NetMulticast,Reliable)
	void onDoorChanged();

	AStuckInsideGS* GState;

public:
	AWindowShutters();

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess),BlueprintReadOnly)
	USceneComponent* Outside;
	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess),BlueprintReadOnly)
	USceneComponent* Inside;

	UFUNCTION(Server,Reliable)
	void Close();

	virtual void BeginPlay() override;

	UFUNCTION(BlueprintImplementableEvent)
	void DoorChangeEvent(bool isOpen);

	UFUNCTION(BlueprintGetter)
	bool getIsOpened(){ return isOpened; }

	void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

	virtual FString getToolTip() override
	{
		return !GState->PowerActive ? "NO POWER" : isOpened ? "Close Window" : "Open Window";
	}
};
