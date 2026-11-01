// Fill out your copyright notice in the Description page of Project Settings.

#include "Tank.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Components/InputComponent.h"
#include "Kismet/GameplayStatics.h"

ATank::ATank()
{
	PrimaryActorTick.bCanEverTick = true;

	this->_spring = this->CreateDefaultSubobject<USpringArmComponent>("SPRING");
	this->_spring->AttachToComponent(this->RootComponent, FAttachmentTransformRules::SnapToTargetIncludingScale);

	this->_camera = this->CreateDefaultSubobject<UCameraComponent>("CAMERA");
	this->_camera->AttachToComponent(this->_spring, FAttachmentTransformRules::SnapToTargetIncludingScale);
}

void ATank::BeginPlay()
{
	Super::BeginPlay();
	this->_controller = Cast<APlayerController>(this->GetController());
}

void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (!this->_controller) return;

	this->_controller->GetHitResultUnderCursor(ECC_Visibility, true, this->_hitResult);

	if (!this->_hitResult.bBlockingHit) return;

	this->RotateTurretTowards(this->_hitResult.ImpactPoint);
}

void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	PlayerInputComponent->BindAxis(*this->_moveForwardAxis.ToString(), this, &ATank::Move);
	PlayerInputComponent->BindAxis(*this->_turnAxis.ToString(), this, &ATank::Turn);
	PlayerInputComponent->BindAction(*this->_fireAction.ToString(), EInputEvent::IE_Pressed, this, &ATank::Fire);
}

void ATank::Move(float value)
{
	this->_movementDirection.Y = value * this->_speed * UGameplayStatics::GetWorldDeltaSeconds(this);
	this->AddActorLocalOffset(this->_movementDirection, true);
}

void ATank::Turn(float value)
{
	FQuat delta = FQuat(this->GetActorUpVector(), value * FMath::DegreesToRadians(this->_turnRate) * UGameplayStatics::GetWorldDeltaSeconds(this));
	this->AddActorLocalRotation(delta, true);
}

void ATank::OnDeath()
{
	Super::OnDeath();

	if (this->_controller == nullptr) return;

	if (this->_deathCameraShake != nullptr)
	{
		this->_controller->ClientStartCameraShake(this->_deathCameraShake);
	}

	this->DisableInput(this->_controller);
	this->_controller->bShowMouseCursor = false;
}