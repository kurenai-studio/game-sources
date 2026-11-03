// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "Switchable.generated.h"


DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FSwitchEvent, AActor*, SwitchingActor, bool, SwitchState);

UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class BUILDINGESCAPEONE_API USwitchable : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	USwitchable();

	// Called when the game starts
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;

	// Enable switch change by BluePrint
	UFUNCTION(BlueprintCallable, Category = "SwitchState")
	void ChangeSwitchState();

	// Setter for SwitchState
	void SetSwitchState(bool State);

	// Propage switch changes by eventsystem
	UPROPERTY(BlueprintAssignable, BlueprintCallable, Category = "Level Events")
	FSwitchEvent SwitchEvent;

private:
	// Remember the actual state
	bool SwitchState = false;
	
};
