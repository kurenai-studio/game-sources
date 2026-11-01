#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SeagullProjectile.generated.h"

class UPaperFlipbookComponent;
class USphereComponent;
class UProjectileMovementComponent;

UCLASS()
class ASeagullProjectile : public AActor
{
	GENERATED_BODY()

public:
	ASeagullProjectile();

	void InitProjectile(const FVector& Direction, float InDamage, float Speed);

	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere)
	USphereComponent* CollisionComponent;

	UPROPERTY(VisibleAnywhere)
	UPaperFlipbookComponent* SpriteComponent;

	UPROPERTY(VisibleAnywhere)
	UProjectileMovementComponent* ProjectileMovement;

	float Damage = 20.f;
	float LifeTime = 3.f;

private:
	UFUNCTION()
	void OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor,
		UPrimitiveComponent* OtherComp, int32 OtherBodyIndex,
		bool bFromSweep, const FHitResult& SweepResult);
};
