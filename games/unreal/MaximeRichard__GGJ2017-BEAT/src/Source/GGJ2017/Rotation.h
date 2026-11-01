// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "Rotation.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class GGJ2017_API URotation : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	URotation();

	// Called when the game starts
	virtual void BeginPlay() override;
	
	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;

	UFUNCTION(BlueprintCallable, Category="Enemy")
	void SetSpeed(float SpeedValue);
	void SetMove(float MoveValue);
	void SetShoot(bool ShootValue);

	UFUNCTION(BlueprintCallable, Category = "RandomMove")
		void Randomize(int choice);
	

private:	

	void EnemyRotation(float DeltaTime);
	void EnemyLevelUpDown(float DeltaTime);
	
	float RandomNumber(float Min, float Max);

	float Movement = 30.f;
	float Speed;
	bool Shoot = false;
	AActor* Actor = nullptr;
	
};
