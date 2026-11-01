// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Sound/SoundBase.h"
#include "Animation/AnimMontage.h"
#include "CustomCharacterMovementComponent.generated.h"



class AGrindingPlatform;
class USplineComponent;

USTRUCT()
struct FGrindState
{
	GENERATED_BODY();

	UPROPERTY()
	TWeakObjectPtr<AGrindingPlatform> GrindingPlatform = nullptr;

	UPROPERTY()
	TWeakObjectPtr<USplineComponent> GrindSpline = nullptr;

	FQuat GrindDetectionRotation{};

	FQuat GrindEntryRotation{};

	FVector GrindDetectionLocation{};

	FVector GrindEntryLocation{};

	float CharacterHalfHeight = 0.0f;

	float MoveToGrindEntryPointDuration = 0.2f;

	float MoveToGrindEntryTimeElapsed = 0.0f;

	float DistanceAlongGrind = 0.0f;

	bool bGrindingForward = true;

	bool bMovingToGrindEntryPoint = true;

};


UENUM(BlueprintType, DisplayName = "WallRunSide")
enum EWallRunSide : uint8
{
	EWRS_None	UMETA(DisplayName = "None"),
	EWRS_LeftSide UMETA(DisplayName = "Left Side"),
	EWRS_RightSide UMETA(DisplayName = "Right Side"),

	EWRS_MAX	   UMETA(Hidden),
};

enum ECornerType : uint8
{
	ECT_Inner	UMETA(DisplayName = "Inner"),
	ECT_Outer	UMETA(DisplayName = "Outer"),

	ECT_MAX		UMETA(Hidden),
};

DECLARE_DELEGATE_TwoParams(FOnCornerTurnBeginSignature, const FVector& CornerTurnDirection, const ECornerType CornerType);
DECLARE_DELEGATE(FOnCornerTurnEndSignature);

DECLARE_DELEGATE(FOnGrindBeginSignature);
DECLARE_DELEGATE(FOnGrindEndSignature);





/**
 *
 */
UCLASS()
class OBSTACLEASSAULT_API UCustomCharacterMovementComponent : public UCharacterMovementComponent
{
	GENERATED_BODY()



public:

	virtual void BeginPlay() override;

	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	virtual void AddInputVector(FVector WorldVector, bool bForce = false) override;


	UFUNCTION(BlueprintCallable)
	bool IsWallRunning() const;

	UFUNCTION(BlueprintCallable)
	FORCEINLINE EWallRunSide GetWallRunSide() const { return WallRunSide; }



	UFUNCTION(BlueprintCallable)
	FORCEINLINE bool IsTurningAroundCorner() const { return bIsTurningAroundCorner; }

	virtual bool CanAttemptJump() const override;

	void WallRunStart();

	void WallRunStop();

	UFUNCTION(BlueprintCallable)
	bool IsGrinding() const;


	UFUNCTION(BlueprintCallable, Category = "Dash")
	bool TryDash();

	UFUNCTION(BlueprintPure, Category = "Dash")
	bool IsDashing() const;

	DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnDashStarted);

	UPROPERTY(BlueprintAssignable, Category = "Dash")
	FOnDashStarted OnDashStarted;




public:

	FOnCornerTurnBeginSignature OnCornerTurnBegin;

	FOnCornerTurnEndSignature OnCornerTurnEnd;

	FOnGrindBeginSignature OnGrindBegin;

	FOnGrindEndSignature OnGrindEnd;

private:

	bool bWallRunInitiated = false;

	FHitResult WallRunHitResult{};

	FVector WallRunControlInputVector{};

	bool bWantsToWallRun = false;


	UPROPERTY(EditAnywhere, Category = Movement, meta = (DisplayName = "Auto wall run"))
	bool bAutoWallRun = true;

	UPROPERTY(Transient)
	TWeakObjectPtr<AActor> PrevNonWallRunnableActor{ nullptr };

	FTimerHandle WallRunCoolDownTimer;

	double WallSearchTraceDistance = 0.0f;

	UPROPERTY(EditAnywhere, Category = Movement, meta = (DisplayName = "Wall Run Rotation Speed"))
	float WallRunRotationInterpSpeed = 5.0f;

	UPROPERTY(EditAnywhere, Category = Movement, meta = (DisplayName = "Wall Run Speed"))
	float WallRunSpeed = 550.0f;

	UPROPERTY(EditAnywhere, Category = Movement, meta = (DisplayName = "Wall Run Cooldown Duration"))
	float WallRunCoolDownDuration = 0.7f;

	UPROPERTY(EditAnywhere, Category = Movement, meta = (DisplayName = "Wall Run Corner Turn Duration"))
	float WallRunCornerTurnDuration = 0.3f;

	bool bIsTurningAroundCorner = false;

	EWallRunSide WallRunSide{ EWRS_None };

	UPROPERTY(EditAnywhere, Category = Grinding, meta = (DisplayName = "Grind Detection Radius"))
	float GrindDetectionRadius = 50.0f;

	UPROPERTY(EditAnywhere, Category = Grinding, meta = (DisplayName = "Grind Speed"))
	float GrindSpeed = 600.0f;


	UPROPERTY()
	FGrindState GrindState{};

	float GrindDetectionRadiusSquared;

protected:

	UFUNCTION()
	virtual void OnCapsuleHit(UPrimitiveComponent* HitComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, FVector NormalImpulse, const FHitResult& Hit);

	bool CanWallRun() const;

	virtual void InitWallRun();

	virtual void CalcWallRunRotation(FRotator& OutWallRunRotation);

	UFUNCTION()
	virtual void OnWallRunInitComplete();

	virtual void PhysCustom(float deltatime, int32 Iterations) override;

	virtual void PhysWallRunning(float deltatime, int32 Iterations);

	virtual void OnMovementModeChanged(EMovementMode PreviousMovementMode, uint8 PreviousCustomMode) override;

	virtual void HandleWallRunCorner(const ECornerType CornerType);

	UFUNCTION()
	virtual void OnTurnedAroundCorner();

	virtual void PhysFalling(float deltatime, int32 Iterations) override;

	virtual bool TryEnterGrind();

	virtual void PhysGrinding(float deltatime, int32 Iterations);

	virtual void OnMovementUpdated(float deltaseconds, const FVector& OldLocation, const FVector& OldVelocity);

	void PhysDashing(float deltatime, int32 iterations);
	bool CanDash() const;

	UPROPERTY(EditDefaultsOnly, Category = "Dash")
	float DashSpeed = 2000.0f;

	UPROPERTY(EditDefaultsOnly, Category = "Dash")
	float DashDuration = 0.2f;

	UPROPERTY(EditDefaultsOnly, Category = "Dash")
	float DashCoolDownDuration = 1.0f;

	UPROPERTY(EditDefaultsOnly, Category = "Dash")
	int32 MaxAirDashes = 1;

	int32 NumAirDashesUsed = 0;
	float DashTimeElapsed = 0.0f;
	FVector DashDirection = FVector::ZeroVector;
	FTimerHandle DashCoolDownTimer;

	bool IsWallRunnableWallNearby() const;


	UPROPERTY(EditAnywhere, Category = "Dash")
	TObjectPtr<USoundBase> DashSound;

	UPROPERTY(EditAnywhere, Category = "Dash")
	TObjectPtr<UAnimMontage> DashMontage;

	bool IsWallRunnableWallInDirection(const FVector& Direction) const;

	UPROPERTY(EditDefaultsOnly, Category = "Dash")
	float PostDashWallRunLockoutDuration = 0.5f;

	FTimerHandle PostDashWallRunLockoutTimer;


};