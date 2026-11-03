// Fill out your copyright notice in the Description page of Project Settings.

#include "PawnTank.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
// Called when the game starts or when spawned

APawnTank::APawnTank()
{	
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Camera SpringArm"));
	SpringArm->SetupAttachment(RootComponent);

    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
}

void APawnTank::BeginPlay()
{
	Super::BeginPlay();

    PlayerControllerRef = Cast<APlayerController>(GetController());
	
}

void APawnTank::HandleDestruction() 
{
    Super::HandleDestruction();
    //Hide Player, Create new function to handle this
}

// Called every frame
void APawnTank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
    Rotate();
    Move();

    if(PlayerControllerRef){

        FHitResult TraceHitResult;
        PlayerControllerRef->GetHitResultUnderCursor(ECC_Visibility, false, TraceHitResult);
        FVector HitLocation = TraceHitResult.ImpactPoint;

        RotateTurret(HitLocation);
    }


}

// Called to bind functionality to input
void APawnTank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
    PlayerInputComponent->BindAxis("MoveForward", this, &APawnTank::CalculateMovement);
    PlayerInputComponent->BindAxis("Turn", this, &APawnTank::CalculateRotation);
    PlayerInputComponent->BindAction("Fire", IE_Pressed, this, &APawnTank::Fire);

}

void APawnTank::CalculateMovement(float value) 
{
    MoveDirection = FVector(value * MoveSpeed * GetWorld()->DeltaTimeSeconds, 0, 0);
}

void APawnTank::CalculateRotation(float value) 
{
    float RotateAmount = value * RotateSpeed * GetWorld()->DeltaTimeSeconds;
    FRotator Rotation = FRotator(0, RotateAmount, 0);
    RotationDirection = FQuat(Rotation);
}   

void APawnTank::Move() 
{   
    FVector location = this->GetActorLocation();
    // UE_LOG(LogTemp, Warning, TEXT("PlayerTank location - X: %f, Y: %f, Z: %f"), location.X, location.Y, location.Z);
    AddActorLocalOffset(MoveDirection, true);
}

void APawnTank::Rotate() 
{
    AddActorLocalRotation(RotationDirection, true);
}

