// Copyright Kevin Luu 2021

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "OpenDoorComponent.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class BUILDINGESCAPE_API UOpenDoorComponent : public UActorComponent
{
	GENERATED_BODY()

private:
	FRotator InitialRotation;
	float TargetYaw;
	float StartingYaw;
	float CurrentYaw;

public:	
	// Sets default values for this component's properties
	UOpenDoorComponent();
	void HandleOpenDoor();
	void HandleCloseDoor() const;

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

		
};
