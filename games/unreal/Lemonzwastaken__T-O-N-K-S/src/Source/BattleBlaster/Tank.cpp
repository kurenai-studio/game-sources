// Fill out your copyright notice in the Description page of Project Settings.

#include "Tank.h"

#include "Camera/CameraComponent.h"
#include "InputMappingContext.h"
#include "Kismet/GameplayStatics.h"
#include "HealthComponent.h"
#include "Components/AudioComponent.h"

#include "HealthBar.h"


ATank::ATank()
{

	Team = ETeam::Player;

	SpringArmComp = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArmComp"));
	SpringArmComp->SetupAttachment(CapsuleComp);

	CameraComp = CreateDefaultSubobject<UCameraComponent>(TEXT("CameraComp"));
	CameraComp->SetupAttachment(SpringArmComp);

	EngineAudioComp = CreateDefaultSubobject<UAudioComponent>(TEXT("EngineAudioComp"));
	EngineAudioComp->SetupAttachment(BaseMesh);
	EngineAudioComp->bAutoActivate = false;

}

// Called when the game starts or when spawned
void ATank::BeginPlay()
{
	Super::BeginPlay();

	// Store the controller in the member variable
	PlayerController = Cast<APlayerController>(GetController());

	if (PlayerController)
	{
		if (ULocalPlayer* LocalPlayer = PlayerController->GetLocalPlayer())
		{
			if (UEnhancedInputLocalPlayerSubsystem* Subsystem =
				ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(LocalPlayer))
			{
				Subsystem->AddMappingContext(DefaultMappingContext, 0);
			}
		}
	}

	SetPlayerEnabled(false);

	if (EngineSound)
	{
		EngineAudioComp->SetSound(EngineSound);
		EngineAudioComp->Play();
	}



	HealthComp = FindComponentByClass<UHealthComponent>();
	if (HealthComp)
	{
		HealthComp->OnHealthChanged.AddDynamic(this, &ATank::UpdateHealthBar);

	}

	if (PlayerController && HealthBarClass)
	{
		UE_LOG(LogTemp, Warning, TEXT("Attempting to create HealthBar widget"));

		HealthBarWidget = CreateWidget<UHealthBar>(PlayerController, HealthBarClass);
		if (HealthBarWidget)
		{
			UE_LOG(LogTemp, Warning, TEXT("HealthBar widget created successfully, adding to screen"));
			HealthBarWidget->AddToPlayerScreen(10);
		}
		else
		{
			UE_LOG(LogTemp, Error, TEXT("CreateWidget returned null!"));
		}
	}
	else
	{
		UE_LOG(LogTemp, Error, TEXT("PlayerController valid: %s, HealthBarClass valid: %s"),
			PlayerController ? TEXT("true") : TEXT("false"),
			HealthBarClass ? TEXT("true") : TEXT("false"));
	}



}

// Called every frame
void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (bIsBraking)
	{
		CurrentMoveInput = FMath::FInterpConstantTo(CurrentMoveInput, 0.0f, DeltaTime, BrakeDeceleration / Speed);
	}
	else
	{
		CurrentMoveInput = FMath::FInterpConstantTo(CurrentMoveInput, TargetMoveInput, DeltaTime, Acceleration / Speed);
	}

	if (EngineAudioComp)
	{
		float PitchAlpha = FMath::Abs(CurrentMoveInput);
		float TargetPitch = FMath::Lerp(MinEnginePitch, MaxEnginePitch, PitchAlpha);
		EngineAudioComp->SetPitchMultiplier(TargetPitch);
	}

	FVector DeltaLocation = FVector::ZeroVector;
	DeltaLocation.X = Speed * CurrentMoveInput * DeltaTime;

	FHitResult HitResult;
	AddActorLocalOffset(DeltaLocation, true, &HitResult);

	if (HitResult.bBlockingHit)
	{
		CurrentMoveInput = 0.0f;
		TargetMoveInput = 0.0f;
	}

	CurrentRecoilOffset = FMath::FInterpTo(CurrentRecoilOffset, 0.0f, DeltaTime, RecoilRecoverySpeed);
	TurretMesh->SetRelativeRotation(FRotator(CurrentRecoilOffset, CurrentTurretYaw, 0.0f));

	// Camera follows turret yaw only — preserve existing pitch/roll
	FRotator CurrentSpringArmRotation = SpringArmComp->GetRelativeRotation();
	SpringArmComp->SetRelativeRotation(FRotator(CurrentSpringArmRotation.Pitch, CurrentTurretYaw, CurrentSpringArmRotation.Roll));
}


// Called to bind functionality to input
void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	if (UEnhancedInputComponent* EIC = Cast<UEnhancedInputComponent>(PlayerInputComponent))
	{
		EIC->BindAction(MoveAction, ETriggerEvent::Triggered, this, &ATank::MoveInput);
		EIC->BindAction(MoveAction, ETriggerEvent::Completed, this, &ATank::MoveInputCompleted);
		EIC->BindAction(TurnAction, ETriggerEvent::Triggered, this, &ATank::TurnInput);
		EIC->BindAction(TurretTurnAction, ETriggerEvent::Triggered, this, &ATank::TurretTurnInput);
		EIC->BindAction(FireAction, ETriggerEvent::Started, this, &ATank::Fire);
		EIC->BindAction(BrakeAction, ETriggerEvent::Started, this, &ATank::BrakeInput);
		EIC->BindAction(BrakeAction, ETriggerEvent::Completed, this, &ATank::BrakeInputCompleted);
	}
}



void ATank::Fire()
{
	float CurrentTime = GetWorld()->GetTimeSeconds();

	if (CurrentTime - LastFireTime < FireCooldown)
	{
		return;
	}

	LastFireTime = CurrentTime;

	Super::Fire();

	CurrentRecoilOffset = RecoilKickAmount;
}

void ATank::BrakeInput(const FInputActionValue& Value)
{
	bIsBraking = true;
}

void ATank::BrakeInputCompleted(const FInputActionValue& Value)
{
	bIsBraking = false;
}

void ATank::TurretTurnInput(const FInputActionValue& Value)
{
	float InputValue = Value.Get<float>();
	CurrentTurretYaw += TurretTurnRate * InputValue * GetWorld()->GetDeltaSeconds();
}

void ATank::MoveInput(const FInputActionValue& Value)
{

	TargetMoveInput = Value.Get<float>();
}

void ATank::MoveInputCompleted(const FInputActionValue& Value)
{

	TargetMoveInput = 0.0f;

}

void ATank::TurnInput(const FInputActionValue& Value)
{
	float InputValue = Value.Get<float>();

	FRotator DeltaRotation = FRotator::ZeroRotator;
	DeltaRotation.Yaw = TurnRate * InputValue * GetWorld()->GetDeltaSeconds();

	AddActorLocalRotation(DeltaRotation, true);
}

void ATank::HandleDestruction()
{
	Super::HandleDestruction();

	UE_LOG(LogTemp, Display, TEXT("Tank HandleDestruction!"));

	SetActorHiddenInGame(true);
	SetActorTickEnabled(false);
	SetPlayerEnabled(false);

	IsAlive = false;
}

void ATank::SetPlayerEnabled(bool Enabled)
{
	if (PlayerController)
	{
		if (Enabled)
		{
			EnableInput(PlayerController);
		}
		else
		{
			DisableInput(PlayerController);
		}
	}
}

void ATank::UpdateHealthBar(float CurrentHealth, float maxHealth)
{

	if (HealthBarWidget)
	{
		HealthBarWidget->SetHealthPercent(CurrentHealth / maxHealth);
	}

}
