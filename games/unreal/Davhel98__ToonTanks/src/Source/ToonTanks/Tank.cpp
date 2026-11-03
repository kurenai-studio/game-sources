// Fill out your copyright notice in the Description page of Project Settings.


#include "Tank.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Kismet/GameplayStatics.h"


ATank::ATank()
{
	PrimaryActorTick.bCanEverTick = true;
	bIsAlive = true;

	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArm->SetupAttachment(RootComponent);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
}

// Called when the game starts or when spawned
void ATank::BeginPlay()
{
	Super::BeginPlay();

	TankPlayerController = Cast<APlayerController>(GetController());
	
}

// Called every frame
void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if(TankPlayerController)
	{
		FHitResult HitResult;
		TankPlayerController->GetHitResultUnderCursor(
			ECollisionChannel::ECC_Visibility,
			false,
			HitResult);
		
		if(DebugEnabled)
		DrawDebugSphere(
			GetWorld(),
			//GetActorLocation() + FVector(0.f, 0.f, 200.f),
			HitResult.ImpactPoint,
			50.f,
			12,
			FColor::Purple,
			false,
			-1.f);

		RotateTurret(HitResult.ImpactPoint);
	}
		
	
	
}

void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ATank::Move);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &ATank::Turn);
	PlayerInputComponent->BindAction(TEXT("Fire"), EInputEvent::IE_Pressed, this, &ATank::Fire);
}


void ATank::Move(const float Value)
{
	FVector DeltaLocation = FVector::ZeroVector;
	const float DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
	DeltaLocation.X = Value * DeltaTime * Speed;

	AddActorLocalOffset(DeltaLocation, true);
}

void ATank::Turn(float Value)
{
	//FRotator DeltaRotation(0, Value * DeltaTime, 0);
	FRotator DeltaRotation = FRotator::ZeroRotator;
	const float DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
	DeltaRotation.Yaw = Value * DeltaTime * TurnRate;

	AddActorLocalRotation(DeltaRotation, true);
}

void ATank::HandleDestruction()
{
	Super::HandleDestruction();
	SetActorHiddenInGame(true);
	SetActorTickEnabled(false);
	bIsAlive = false;
}
