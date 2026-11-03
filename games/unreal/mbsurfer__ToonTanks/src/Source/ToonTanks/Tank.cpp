// Fill out your copyright notice in the Description page of Project Settings.


#include "Tank.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Kismet/GameplayStatics.h"
#include "InputAction.h"
#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"

ATank::ATank()
{
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
    SpringArm->SetupAttachment(RootComponent);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
    Camera->SetupAttachment(SpringArm);
}

AToonTanksPlayerController* ATank::GetTankPlayerController() const
{
    return TankPlayerController;
}

void ATank::HandleDestruction()
{
    Super::HandleDestruction();

    SetActorHiddenInGame(true);
    SetActorTickEnabled(false);
    bAlive = false;
}

// Called when the game starts or when spawned
void ATank::BeginPlay()
{
	Super::BeginPlay();

    TankPlayerController = Cast<AToonTanksPlayerController>(GetController());

    if (TankPlayerController)
    {
        if (UEnhancedInputLocalPlayerSubsystem* Subsystem = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(TankPlayerController->GetLocalPlayer()))
        {
            Subsystem->AddMappingContext(MappingContext, 0);
        }
    }
}

// Called to bind functionality to input
void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    if (UEnhancedInputComponent* EnhancedInputAction = CastChecked<UEnhancedInputComponent>(PlayerInputComponent))
    {
        EnhancedInputAction->BindAction(MoveAction, ETriggerEvent::Triggered, this, &ATank::Move);
        EnhancedInputAction->BindAction(TurnAction, ETriggerEvent::Triggered, this, &ATank::Turn);
        EnhancedInputAction->BindAction(FireAction, ETriggerEvent::Started, this, &ATank::Fire);
    }
}

// Called every frame
void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

    // The tank turret should follow the player's mouse
    if (TankPlayerController)
    {
        FHitResult HitResult;
        bool ShouldRotate = TankPlayerController->GetHitResultUnderCursor(
            ECollisionChannel::ECC_Visibility,
            false,
            HitResult
        );
        RotateTurret(HitResult.ImpactPoint);
    }
}

void ATank::Move(const FInputActionValue& Value)
{
    FVector DeltaLocation = FVector::ZeroVector;
    double DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
    DeltaLocation.X = Value.Get<float>() * DeltaTime * Speed;
    AddActorLocalOffset(DeltaLocation, true);
}

void ATank::Turn(const FInputActionValue& Value)
{
    FRotator DeltaRotation = FRotator::ZeroRotator;
    double DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
    DeltaRotation.Yaw = Value.Get<float>() * DeltaTime * TurnRate;
    AddActorLocalRotation(DeltaRotation, true);
}

void ATank::Fire(const FInputActionValue& Value)
{
   Super::Fire();
}