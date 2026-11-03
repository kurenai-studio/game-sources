// Fill out your copyright notice in the Description page of Project Settings.


#include "PawnTank.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"

APawnTank::APawnTank()
{
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArm->SetupAttachment(RootComponent);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
}

// Called when the game starts or when spawned
void APawnTank::BeginPlay()
{
	Super::BeginPlay();

	PlayerControllerRef = Cast<APlayerController>(GetController());
	
}

void APawnTank::HandleDestruction() 
{
	Super::HandleDestruction();

	bIsPlayerAlive = false;

	SetActorHiddenInGame(true);

	// Disable ticking, where movement and rotation logic is being handled
	SetActorTickEnabled(false);
}

bool APawnTank::GetIsPlayerAlive() const
{
	return bIsPlayerAlive;
}

// Called every frame
void APawnTank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	Rotate();
	Move();

	if (PlayerControllerRef)
	{
		FHitResult TraceHitResult;
		bool bComplexTracing = false;
		PlayerControllerRef->GetHitResultUnderCursor(ECC_Visibility, bComplexTracing, TraceHitResult);

		FVector HitLocation = TraceHitResult.ImpactPoint;
		RotateTurretTowardsTarget(HitLocation);
	}
}

// Called to bind functionality to input
void APawnTank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	PlayerInputComponent->BindAxis("MoveForward", this, &APawnTank::CalculateMoveInput);
	PlayerInputComponent->BindAxis("Turn", this, &APawnTank::CalculateRotateInput);

	PlayerInputComponent->BindAction("Fire", IE_Pressed, this, &APawnTank::Fire);
}

void APawnTank::CalculateMoveInput(float Value) 
{
	// X axis is the forward direction
	MoveDirection = FVector(Value * MoveSpeed * GetWorld()->DeltaTimeSeconds, 0, 0);
}

void APawnTank::CalculateRotateInput(float Value) 
{
	const float YawRotateAmount = Value * RotateSpeed * GetWorld()->DeltaTimeSeconds;
	FRotator Rotation = FRotator(0, YawRotateAmount, 0);
	RotationDirection = FQuat(Rotation);
}

void APawnTank::Move() 
{
	const bool bSweep = true;	// Check for collisions
	AddActorLocalOffset(MoveDirection, bSweep);
}

void APawnTank::Rotate() 
{
	const bool bSweep = true;	// Check for collisions
	AddActorLocalRotation(RotationDirection, bSweep);
}

