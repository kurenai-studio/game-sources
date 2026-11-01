// Copy Right Shijie Xiong

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Components/InputComponent.h"
#include "PhysicsEngine/PhysicsHandleComponent.h"
#include "Grab.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class ESCAPE_ROOM_API UGrab : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UGrab();
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

private:
	void SetupInputComponent();
	void SetupPhysicsHandleComponent();
	void GetPlayerViewPoint();
	FVector GetPlayerReachPoint(float Ratio);
	void Grab();
	void Release();
	void UpdateGrabbedComponentLocation();

	UInputComponent* InputComponent = nullptr;
	UPhysicsHandleComponent* PhysicsHandleComponent = nullptr;
	
	UPROPERTY(EditAnywhere)
	float ReachDistance = 200.f;
	const float NormalRatio = 1.f;
	float HitDistanceRatio = 1.f;
	FVector PlayerViewPointLocation;
	FRotator PlayerViewPointRotation;
	
};
