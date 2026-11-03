// Fill out your copyright notice in the Description page of Project Settings.


#include "PawnTank.h"
#include "GameFramework/SpringArmCOmponent.h"
#include "Camera/CameraComponent.h"
#include "Camera/CameraShake.h"


APawnTank::APawnTank()
{
	PrimaryActorTick.bCanEverTick = true;

	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArm->SetupAttachment(RootComponent);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
}

void APawnTank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	Rotate();
	Move();

	if (PlayerControllerRef)
	{
		FHitResult TraceHitResult;
		PlayerControllerRef->GetHitResultUnderCursor(ECC_Visibility, false, TraceHitResult);
		FVector HitLocation = TraceHitResult.ImpactPoint;

		RotateTurretFunction(HitLocation);
	}
}

void APawnTank::SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
	PlayerInputComponent->BindAxis("MoveForward", this, &APawnTank::CalculateMoveInput);
	PlayerInputComponent->BindAxis("Turn", this, &APawnTank::CalculateRoatateInput);
	PlayerInputComponent->BindAction("Fire", IE_Pressed, this, &APawnTank::Fire);
	

}

void APawnTank::BeginPlay()
{
	Super::BeginPlay();

	PlayerControllerRef = Cast<APlayerController>(GetController());
	
}

void APawnTank::HandleDestruction()
{
	Super::HandleDestruction();
	
}

void APawnTank::CalculateMoveInput(float Value)
{
	MoveDirection = FVector(Value * MoveSpeed * GetWorld()->DeltaTimeSeconds,0,0);

}

void APawnTank::CalculateRoatateInput(float Value)
{
	float RotateAmount = Value * RotateSpeed * GetWorld()->DeltaTimeSeconds;
	FRotator Rotation = FRotator(0, RotateAmount, 0);
	RotationDirection = FQuat(Rotation);
}

void APawnTank::Move()
{
	AddActorLocalOffset(MoveDirection, true);
}

void APawnTank::Rotate()
{
	AddActorLocalRotation(RotationDirection, true);
}