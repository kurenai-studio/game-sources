// CopyRight Shijie Xiong 2021

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Engine/TriggerVolume.h"
#include "OpenDoor.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class BUILDING_ESCAPE_API UOpenDoor : public UActorComponent
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
	float TotalMassOfActors() const;
	void FindAudioComponent();

private:
	float InitialYaw;
	float CurrentYaw;
	UPROPERTY(EditAnywhere)
	float DoorRotationYaw = 90.f;
	float TargetYaw;
	UPROPERTY(EditAnywhere)
	float DoorOpenSpeed = 1.f;
	UPROPERTY(EditAnywhere)
	float DoorCloseSpeed = 0.5f;
	UPROPERTY(EditAnywhere)
	ATriggerVolume* PressurePlate;

	float DoorLastOpened = 0.f;
	UPROPERTY(EditAnywhere)
	float DoorCloseDelay = 2.f;
	
	UPROPERTY(EditAnywhere)
	float MassRequired = 50.f;

	UPROPERTY()
	UAudioComponent* AudioComponent = nullptr;

	bool OpenDoorSoundPlayed = false;
	bool CloseDoorSoundPlayed = true;
};
