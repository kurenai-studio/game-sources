// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Interactable.h"
#include "BreakerDoor.generated.h"

/**
 * 
 */
UCLASS()
class STUCKINSIDE_API ABreakerDoor : public AInteractable
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	UStaticMeshComponent* BreakerDoor;

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	float CloseRotationYaw = 0;
	
	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	float OpenRotationYaw = 90;

	UPROPERTY(EditDefaultsOnly,meta=(AllowPrivateAccess))
	float OpenSpeed = 12;

	UPROPERTY(Replicated)
	bool isOpened = false;

	void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
	
	virtual void Interact(ACharacter* Character) override;
public:
	UFUNCTION(Server,Reliable)
	void Close();

	virtual void Tick(float DeltaSeconds) override;

	ABreakerDoor();

	virtual FString getToolTip() override
	{
		return isOpened ? "Close Breaker" : "Open Breaker";
	}
};
