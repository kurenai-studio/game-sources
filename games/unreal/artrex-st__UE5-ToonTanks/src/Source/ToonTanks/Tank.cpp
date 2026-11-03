// Fill out your copyright notice in the Description page of Project Settings.

#include "Tank.h"

#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Kismet/GameplayStatics.h"

ATank::ATank()
{
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArm->SetupAttachment(RootComponent);
	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
}

void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
}

void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	FollowCursor();
}

void ATank::HandlerDestruction()
{
	Super::HandlerDestruction();
	SetActorHiddenInGame(true);
	SetActorTickEnabled(false);
	bAlive = false;
}

void ATank::BeginPlay()
{
	Super::BeginPlay();
	TankPlayerController = Cast<APlayerController>(GetController());
	SetTankLocationZ();
}

void ATank::Move(FVector2D Value)
{
	const float DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
	FVector DeltaLocation = FVector::ZeroVector;
	DeltaLocation.X = Value.X * TankSpeed * DeltaTime;
	AddActorLocalOffset(DeltaLocation, true);
	Turn(Value.Y);
}

void ATank::Turn(float Value)
{
	const float DeltaTime = UGameplayStatics::GetWorldDeltaSeconds(this);
	FRotator Rotation = FRotator::ZeroRotator;
	Rotation.Yaw = Value * TurnRate * DeltaTime;
	AddActorLocalRotation(Rotation, true);
}

void ATank::FollowCursor() const
{
	if (TankPlayerController)
	{
		FHitResult HitResult;
		TankPlayerController->GetHitResultUnderCursor(ECollisionChannel::ECC_Visibility,false,HitResult);
		RotateTurret(HitResult.ImpactPoint);
		//DrawDebugSphere(GetWorld(),HitResult.ImpactPoint,20,10, FColor::Emerald,false, -1);
		//UE_LOG(LogTemp, Display, TEXT("Rotation: %s"), *(HitResult.ImpactPoint - Owner->GetActorLocation()).ToString());
	}
}

void ATank::SetTankLocationZ()
{
	FVector StartLocation = GetActorLocation();
	FVector EndLocation = GetActorUpVector() *-1;
	FHitResult HitResult;

	FCollisionQueryParams CollisionParams;
	CollisionParams.AddIgnoredActor(this);
	GetWorld()->LineTraceSingleByChannel(HitResult, StartLocation, EndLocation, ECC_Visibility, CollisionParams);
	//DrawDebugLine(GetWorld(), StartLocation, EndLocation, FColor::Green, false);

	if (HitResult.bBlockingHit)
	{
		FVector NewLocation = HitResult.ImpactPoint + FVector(0,0,GetCapsuleComponent()->GetUnscaledCapsuleHalfHeight() + .1f);
		//UE_LOG(LogTemp, Warning, TEXT("Ground Position: %s, and Height: %f"), *HitResult.ImpactPoint.ToString(), GetCapsuleComponent()->GetUnscaledCapsuleHalfHeight());
		SetActorLocation(NewLocation);
	}
}
