// Copyright Scott Kolby 2020

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Engine/TriggerVolume.h"
#include "OpenDoor.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FDoorEvent);

UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class BUILDINGESCAPE_API UOpenDoor : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UOpenDoor();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
	void OpenDoor(float DeltaTime);
	void CloseDoor(float DeltaTime);
	float GetTotalMassOfActors() const;
	void FindAudioComponent();
	void FindPressurePlate();

	UPROPERTY(BlueprintAssignable)
	FDoorEvent OnOpen;

	UPROPERTY(BlueprintAssignable)
	FDoorEvent OnClose;

private:
	/*float InitialYaw;
	float CurrentYaw;*/

	/*UPROPERTY(EditAnywhere)
	float OpenYaw = 90.0f;*/

	float DoorLastOpened = 0.0f;

	/*UPROPERTY(EditAnywhere)
	float DoorOpenSpeed = 3.0f;*/

	/*UPROPERTY(EditAnywhere)
	float DoorCloseSpeed = 6.0f;*/

	UPROPERTY(EditAnywhere)
	float DoorCloseDelay = 2.0f;

	UPROPERTY(EditAnywhere)
	float DoorOpeningMass = 50.f;

	UPROPERTY(EditAnywhere)
	ATriggerVolume* PressurePlate = nullptr;

	UPROPERTY()
	UAudioComponent* AudioComponent = nullptr;

	bool OpenDoorSoundPlayed = false;
	bool CloseDoorSoundPlayed = true;
};
