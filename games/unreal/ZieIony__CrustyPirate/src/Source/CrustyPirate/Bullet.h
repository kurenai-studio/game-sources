// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Particle.h"
#include "Bullet.generated.h"

class UCapsuleComponent;
class UPaperFlipbookComponent;

UCLASS()
class CRUSTYPIRATE_API ABullet : public AActor
{
	GENERATED_BODY()
	
public:	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UCapsuleComponent* CapsuleComp;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	UPaperFlipbookComponent* Sprite;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FVector Velocity;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int attackDamage = 50;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float attackStunDuration = 0.3f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float attackStunForce = 20000.0f;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AParticle> ParticleClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	USoundBase* HitSound;

	// Sets default values for this actor's properties
	ABullet();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	UFUNCTION()
	void OverlapBegin(
		UPrimitiveComponent* overlappedComponent,
		AActor* otherActor,
		UPrimitiveComponent* otherComponent,
		int32 otherBodyIndex,
		bool fromSweep,
		const FHitResult& sweepResults
	);
};
