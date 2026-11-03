// Created by Balbjorn Bran.


#include "Tank.h"
#include "Camera/CameraComponent.h"
#include "EnhancedInputComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Kismet/GameplayStatics.h"

DEFINE_LOG_CATEGORY(TankLog);

// Sets default values for this class
ATank::ATank()
{
	// Create the spring arm component and attach it to the root
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArm"));
	SpringArm->SetupAttachment(RootComponent);
	SpringArm->TargetArmLength = 300.0f; // Set the desired target arm length
	SpringArm->bEnableCameraLag = true; // Enable camera lag
	SpringArm->CameraLagSpeed = 3.0f;   // Set the camera lag speed

	// Create the camera component and attach it to the spring arm
	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm); // Attach Camera to Spring Arm
}

void ATank::Move(const FInputActionValue& Value)
{
	float DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
	FVector2D MovementVector = Value.Get<FVector2D>();
	FVector DeltaLocation = FVector::ZeroVector;
	DeltaLocation.X = MovementVector.X * DeltaTime * Speed;
	AddActorLocalOffset(DeltaLocation, true);
	
	FRotator DeltaRotation = FRotator::ZeroRotator;
	DeltaRotation.Yaw = MovementVector.Y * DeltaTime * TurnRate;
	AddActorLocalRotation(DeltaRotation, true);
	
}

void ATank::Look(const FInputActionValue& Value)
{
	
}


// Called to bind functionality to input
void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	if (UEnhancedInputComponent* EnhancedInputComponent = Cast<UEnhancedInputComponent>(PlayerInputComponent))
	{
		//Move
		EnhancedInputComponent->BindAction(IA_Move, ETriggerEvent::Triggered, this, &ATank::Move);
	
		// look around 
		EnhancedInputComponent->BindAction(IA_Look, ETriggerEvent::Triggered, this, &ATank::Look);

		// Fire action 
		EnhancedInputComponent->BindAction(IA_Fire, ETriggerEvent::Triggered, this, &ATank::Fire);
		
	}
	else
	{
		UE_LOG(TankLog, Error, TEXT("'%s' Failed to find an Enhanced Input component! This template is built to use the Enhanced Input system. If you intend to use the legacy system, then you will need to update this C++ file."), *GetNameSafe(this));
	}


}

// Called when the game starts or when spawned
void ATank::BeginPlay()
{
	Super::BeginPlay();

	TankPlayerController = Cast<APlayerController>(GetController());
	
}

// Called every frame
void ATank::Tick(float Delta)
{
	Super::Tick(Delta);

	if (TankPlayerController)
	{
		FHitResult HitResult;
		TankPlayerController->GetHitResultUnderCursor(ECC_Visibility, false, HitResult);
		RotateTurret(HitResult.Location);
	}
	
}

void ATank::HandleDestruction()
{
	Super::HandleDestruction();
	bIsAlive = false;
	SetActorHiddenInGame(true);
	SetActorTickEnabled(false);
}

