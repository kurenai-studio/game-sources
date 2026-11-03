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

    // Find active player controller that has been created by the world to handle the player and storing that as our PlayerControllerRef
    PlayerControllerRef = Cast<APlayerController>(GetController());
}

void APawnTank::HandleDestruction()
{
    Super::HandleDestruction();
    // Hide Player. TODO - Create new function to handle this
    bIsPlayerAlive = false;

    SetActorHiddenInGame(true);
    SetActorTickEnabled(false);
}

// So we know the state of player whilst also ensuring that the actual variable itself is not accessible.
bool APawnTank::GetIsPlayerAlive()
{
    return bIsPlayerAlive;
}

// Called every frame
void APawnTank::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    Rotate(); // Process rotation before any movement is applied
    Move();

    if (PlayerControllerRef)
    {
        FHitResult TraceHitResult;

        // Location of where we want the turret to face toward
        PlayerControllerRef->GetHitResultUnderCursor(ECC_Visibility, false, TraceHitResult);

        // Location in the world that the trace has hit and it's going to be the end location we want our tank turret to look at.
        FVector HitLocation = TraceHitResult.ImpactPoint;

        RotateTurret(HitLocation);
    } 
}

// Called to bind functionality to input
void APawnTank::SetupPlayerInputComponent(UInputComponent *PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis("MoveForward", this, &APawnTank::CalculateMoveInput);
    PlayerInputComponent->BindAxis("Turn", this, &APawnTank::CalculateRotateInput);
    PlayerInputComponent->BindAction("Fire", IE_Pressed, this, &APawnTank::Fire);
}

void APawnTank::CalculateMoveInput(float Value)
{
    MoveDirection = FVector(Value * MoveSpeed * GetWorld()->DeltaTimeSeconds, 0, 0);
}

void APawnTank::CalculateRotateInput(float Value)
{
    float RotateAmount = Value * RotateSpeed * GetWorld()->DeltaTimeSeconds;
    FRotator Rotation = FRotator(0, RotateAmount, 0);
    RotationDireciton = FQuat(Rotation);
}

void APawnTank::Move()
{
    AddActorLocalOffset(MoveDirection, true); // Sweep check - check whether collisions should be checked when the actor/pawn is moving
}

void APawnTank::Rotate()
{
    AddActorLocalRotation(RotationDireciton, true);
}
