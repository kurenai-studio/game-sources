// Fill out your copyright notice in the Description page of Project Settings.


#include "Tank.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"

#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "InputMappingContext.h"
#include "Kismet/GameplayStatics.h"
#include "DrawDebugHelpers.h"

#define ENHANCED_INPUT 0

ATank::ATank()
{
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArm->SetupAttachment(RootComponent);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);

	//Enhanced Input
	static ConstructorHelpers::FObjectFinder<UInputMappingContext> DEFAULT_CONTEXT(TEXT("/Game/Input/Actions/iMC_Tank"));
	if (DEFAULT_CONTEXT.Succeeded())
		DefaultContext = DEFAULT_CONTEXT.Object;

	static ConstructorHelpers::FObjectFinder<UInputAction> IA_MOVE_FORWARD(TEXT("/Game/Input/Actions/iA_MoveForward"));
	if (IA_MOVE_FORWARD.Succeeded())
		MoveForwardAction = IA_MOVE_FORWARD.Object;

	static ConstructorHelpers::FObjectFinder<UInputAction> IA_TURN(TEXT("/Game/Input/Actions/iA_Turn"));
	if (IA_TURN.Succeeded())
		TurnAction = IA_TURN.Object;

	static ConstructorHelpers::FObjectFinder<UInputAction> IA_ROTATE_TURRET(TEXT("/Game/Input/Actions/iA_RotateTurret"));
	if (IA_ROTATE_TURRET.Succeeded())
		RotateTurretAction = IA_ROTATE_TURRET.Object;

	static ConstructorHelpers::FObjectFinder<UInputAction> IA_FIRE(TEXT("/Game/Input/Actions/iA_Fire"));
	if(IA_FIRE.Succeeded())
		FireAction = IA_FIRE.Object;
}

void ATank::BeginPlay()
{
	Super::BeginPlay();

	//Enhanced Input
#if ENHANCED_INPUT
	if(APlayerController* PlayerController = Cast<APlayerController>(GetController()))
	{
		if (UEnhancedInputLocalPlayerSubsystem* SubSystem = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(PlayerController->GetLocalPlayer()))
		{
			SubSystem->AddMappingContext(DefaultContext, 0);
		}
	}
#else
	TankPlayerController = Cast<APlayerController>(GetController());
#endif
}

// Called to bind functionality to input
void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	//Enhanced Input
#if ENHANCED_INPUT
	if(UEnhancedInputComponent* EnhancedInputComponent = Cast<UEnhancedInputComponent>(PlayerInputComponent))
	{
		EnhancedInputComponent->BindAction(MoveForwardAction, ETriggerEvent::Triggered, this, &ATank::Move_Enhanced);
		EnhancedInputComponent->BindAction(TurnAction, ETriggerEvent::Triggered, this, &ATank::Turn_Enhanced);
		EnhancedInputComponent->BindAction(FireAction, ETriggerEvent::Triggered, this, &ATank::Fire_Enhanced);
	}
#else
	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ATank::Move);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &ATank::Turn);
	PlayerInputComponent->BindAction(TEXT("Fire"), IE_Pressed, this, &ATank::Fire);
#endif
}

void ATank::Move_Enhanced(const FInputActionValue& Value)
{
	Move(Value.Get<float>());
}

void ATank::Move(float Value)
{
	FVector DeltaLocation = FVector::ZeroVector;

	DeltaLocation.X = Value * Speed * UGameplayStatics::GetWorldDeltaSeconds(this);
	AddActorLocalOffset(DeltaLocation, true);
}

void ATank::Turn_Enhanced(const FInputActionValue& Value)
{
	Turn(Value.Get<float>());
}

void ATank::Turn(float Value)
{
	FRotator DeltaRotation = FRotator::ZeroRotator;

	DeltaRotation.Yaw = Value * TurnRate * UGameplayStatics::GetWorldDeltaSeconds(this);
	AddActorLocalRotation(DeltaRotation, true);
}

void ATank::Fire_Enhanced(const FInputActionValue& Value)
{
	Fire();
}

// Called every frame
void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (TankPlayerController)
	{
		FHitResult HitResult;

		if (TankPlayerController->GetHitResultUnderCursor(
			ECollisionChannel::ECC_Visibility,
			false,
			HitResult))
		{
			RotateTurret(HitResult.ImpactPoint);
		}
	}
}

void ATank::HandleDestruction()
{
	Super::HandleDestruction();

	//탱크는 숨기고 Tick을 멈춘다.
	SetActorHiddenInGame(true);
	SetActorTickEnabled(false);

	bAlive = false;
}



