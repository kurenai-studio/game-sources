// Fill out your copyright notice in the Description page of Project Settings.


#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"

ATank::ATank()
{
	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	SpringArmComp = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArmComp->SetupAttachment(RootComponent);

	CamComp = CreateDefaultSubobject <UCameraComponent>(TEXT("Tank Camera"));
	CamComp->SetupAttachment(SpringArmComp);
}

// Called when the game starts or when spawned
void ATank::BeginPlay()
{
	Super::BeginPlay();

	TankPlayerController = Cast<APlayerController>(GetController());
}

// Called to bind functionality to input
void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ATank::Move);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &ATank::Turn);

	PlayerInputComponent->BindAction(TEXT("Fire"), IE_Pressed, this, &ATank::Fire);
}

void ATank::HandleDestruction()
{
	Super::HandleDestruction();

	//Schovam tank kvuli kamere ale hrac si za nej uz nezahraje
	SetActorHiddenInGame(true);
	SetActorTickEnabled(false);

	bAlive = false;
}

// Called every frame
void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (TankPlayerController)
	{
		FHitResult HitResult;
		TankPlayerController->GetHitResultUnderCursor(ECollisionChannel::ECC_Visibility, false, HitResult);

		RotateTurret(HitResult.ImpactPoint);
	}

}

// Move for Tank
void ATank::Move(float Value)
{
	FVector DeltaLocation = FVector::ZeroVector;
	// X = Value * DeltaTime * Speed;
	DeltaLocation.X = Value * UGameplayStatics::GetWorldDeltaSeconds(this) * TankSpeed;

	AddActorLocalOffset(DeltaLocation,true);
}

// Turn for Tank
void ATank::Turn(float Value)
{
	FRotator DeltaRotation = FRotator::ZeroRotator;
	//DeltaRotation Yaw = Value * DeltaTime * TurnRate;
	DeltaRotation.Yaw = Value * UGameplayStatics::GetWorldDeltaSeconds(this) * TurnRate;

	AddActorLocalRotation(DeltaRotation,true);
}