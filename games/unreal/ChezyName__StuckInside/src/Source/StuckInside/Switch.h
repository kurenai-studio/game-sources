// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Interactable.h"
#include "Switch.generated.h"

/**
 * 
 */
UCLASS()
class STUCKINSIDE_API ASwitch : public AInteractable
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	UStaticMeshComponent* Switch;

	bool RightSide = true;

	virtual void Interact(ACharacter* Character) override;

public:
	ASwitch();

	void BeginPlay() override;
	
	bool getSideActive()
	{
		return RightSide == true;
	}

	void reset()
	{
		RightSide = false;
		if(Switch) Switch->SetRelativeRotation(FRotator(RightSide ? 0 : 180,0,0));
	}

	void activate()
	{
		RightSide = true;
		if(Switch) Switch->SetRelativeRotation(FRotator(RightSide ? 0 : 180,0,0));
	}

	virtual FString getToolTip() override
	{
		return "Toggle Switch";
	}
};
