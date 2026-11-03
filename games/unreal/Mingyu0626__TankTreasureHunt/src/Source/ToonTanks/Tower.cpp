// Fill out your copyright notice in the Description page of Project Settings.


#include "Tower.h"
#include "Tank.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"

void ATower::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	
	// 1. 탱크가 유효하고, 타워의 사정거리 안에 있는지 확인
	if (InFireRange())
	{
		// 2. 사정거리 안에 있으면 포탑 회전
		RotateTurret(Tank->GetActorLocation());
	}
}

void ATower::HandleDestruction()
{
	Super::HandleDestruction();
	Destroy();
}

void ATower::BeginPlay()
{
	Super::BeginPlay();
	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	GetWorldTimerManager().SetTimer(
		FireRateTimerHandle, 
		this, &ATower::CheckFireCondition, 
		FireRate, 
		true);
}

void ATower::CheckFireCondition()
{
	// 탱크가 죽었을때도 범위 안에 있다고 계속 쏘면 안되니까
	if (Tank == nullptr)
	{
		return;
	}

	// 1. 탱크가 살아있고, 타워의 사정거리 안에 있는지 확인
	if (InFireRange() && Tank->bAlive)
	{
		// 2. 사정거리 안에 있으면 Fire 호출
		Fire();	
	}
}

bool ATower::InFireRange()
{
	if (Tank)
	{
		return FVector::Dist(GetActorLocation(), Tank->GetActorLocation()) <= FireRange;
	}
	return false;
}
