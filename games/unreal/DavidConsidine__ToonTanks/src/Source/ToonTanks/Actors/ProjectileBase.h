// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ProjectileBase.generated.h"

class UProjectileMovementComponent;

UCLASS()
class TOONTANKS_API AProjectileBase : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AProjectileBase();

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true"))
	UProjectileMovementComponent* ProjectileMovement;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true"))
	UStaticMeshComponent* ProjectileMesh;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components", meta = (AllowPrivateAccess = "true"))
	UParticleSystemComponent* ParticleTrail;
	
	UPROPERTY(EditDefaultsOnly, Category = "Damage", meta = (AllowPrivateAccess = "true"))
	TSubclassOf<UDamageType> DamageType;
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Movement", meta = (AllowPrivateAccess = "true"))
	float MovementSpeed = 1300.0f;
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Damage", meta = (AllowPrivateAccess = "true"))
	float Damage = 50.0f;

	// EFFECTS
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Effects", meta = (AllowPrivateAccess = "True"))
    UParticleSystem* HitParticle;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Effects", meta = (AllowPrivateAccess = "True"))
	USoundBase* HitSound;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Effects", meta = (AllowPrivateAccess = "True"))
	USoundBase* LaunchSound;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Effects", meta = (AllowPrivateAccess = "True"))
	TSubclassOf<UCameraShake> HitShake;
	
	UFUNCTION()
	void OnHit(UPrimitiveComponent* HitComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, FVector NormalImpulse, const FHitResult& Hit);
	
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

};
