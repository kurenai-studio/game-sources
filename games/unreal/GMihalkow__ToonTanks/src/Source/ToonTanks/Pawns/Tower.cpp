// Fill out your copyright notice in the Description page of Project Settings.

#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"
#include "../Health.h"
#include "../ToonTanksGameMode.h"

ATower::ATower()
{
	PrimaryActorTick.bCanEverTick = true;
}

void ATower::BeginPlay()
{
	Super::BeginPlay();

	this->_target = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));

	this->GetWorldTimerManager().SetTimer(this->_timerHandle, this, &ATower::OnShootTimer, this->_shootInterval, true);
}

void ATower::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (this->_target == nullptr) return;

	if (!TargetIsInRange()) return;

	this->RotateTurretTowards(this->_target->GetActorLocation(), 10.f);
}

void ATower::OnShootTimer()
{
	if (this->_health->IsDead() || this->_gameMode->PlayerDied() || !TargetIsInRange()) return;

	this->Fire();
}

bool ATower::TargetIsInRange()
{
	if (_target == nullptr)
	{
		return false;
	}

	float distance = FVector::Distance(this->GetActorLocation(), this->_target->GetActorLocation());

	return distance <= this->_aggroRange;
}

void ATower::OnDeath()
{
	Super::OnDeath();

	this->GetWorldTimerManager().ClearTimer(this->_timerHandle);
}
