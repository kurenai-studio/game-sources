#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Core/SeagullTypes.h"
#include "SeagullPickup.generated.h"

class UPaperFlipbookComponent;
class USphereComponent;
class ASeagullPlayerPawn;

UCLASS()
class ASeagullPickup : public AActor
{
	GENERATED_BODY()

public:
	ASeagullPickup();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	virtual void OnPickedUp(ASeagullPlayerPawn* Player);

	UPROPERTY(VisibleAnywhere)
	USphereComponent* CollisionComponent;

	UPROPERTY(VisibleAnywhere)
	UPaperFlipbookComponent* SpriteComponent;

	ESeagullPickupType PickupType = ESeagullPickupType::XP;

protected:
	UFUNCTION()
	void OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex,
		bool bFromSweep, const FHitResult& SweepResult);
};
