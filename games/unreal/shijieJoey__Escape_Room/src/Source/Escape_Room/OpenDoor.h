// Copy Right Shijie Xiong

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Engine/TriggerVolume.h"
#include "OpenDoor.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class ESCAPE_ROOM_API UOpenDoor : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UOpenDoor();
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

private:

	void SetupAudioComponent();
	void SetupTriggerVolume();
	void SetupDoorRotation();
	float GetTotalMassOfActors() const;
	void DoorAction(float DeltaTime);
	void OpenDoor(float DeltaTime);
	void CloseDoor(float DeltaTime);

	UPROPERTY(EditAnywhere)
	ATriggerVolume* TriggerVolume = nullptr;
	UAudioComponent* AudioComponent = nullptr;
	UPROPERTY(EditAnywhere)
	bool DoorClosed = true;
	UPROPERTY(EditAnywhere)
	bool DoorOpend = false;
	UPROPERTY(EditAnywhere)
	float MinMassRequired = 0.f;
	UPROPERTY(EditAnywhere)
	float MaxMassRequired = 100.f;
	UPROPERTY(EditAnywhere)
	float DoorOpenSpeed = 1.f;
	UPROPERTY(EditAnywhere)
	float DoorCloseSpeed = 2.f;
	UPROPERTY(EditAnywhere)
	float DoorOpenRotationYaw = 90.f;
	UPROPERTY(EditAnywhere)
	float DoorCloseDelay = 2.f;

	float InitialRotationYaw;
	float CurrentRotationYaw;
	float TargetRotationYaw;
	float DoorLastOpened = 0.f;

		
};
