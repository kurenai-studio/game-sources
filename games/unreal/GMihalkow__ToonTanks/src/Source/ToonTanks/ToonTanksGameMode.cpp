// Fill out your copyright notice in the Description page of Project Settings.

#include "ToonTanksGameMode.h"
#include "Pawns/Tank.h"
#include "Pawns/Tower.h"
#include "Kismet/GameplayStatics.h"
#include "ToonTanksPlayerController.h"

void AToonTanksGameMode::BeginPlay()
{
	Super::BeginPlay();

	this->_tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this->GetWorld(), 0));
	this->_playerController = Cast<AToonTanksPlayerController>(UGameplayStatics::GetPlayerController(this->GetWorld(), 0));

	this->OnGameStart();
}

void AToonTanksGameMode::OnActorDied(const AActor* actor)
{
	if (actor != this->_tank)
	{
		this->_defeatedTowersCount++;

		if (this->_targetTowersCount == this->_defeatedTowersCount)
		{
			this->GameOver(true);
		}

		return;
	}

	UE_LOG(LogTemp, Log, TEXT("THE PLAYER JUST DIED!"));

	this->_playerDied = true;
	this->_playerController->ToggleEnabledInputState(false);
	this->GameOver(false);
}

bool AToonTanksGameMode::PlayerDied() const
{
	return this->_playerDied;
}

void AToonTanksGameMode::OnGameStart()
{
	if (this->_playerController == nullptr) return;

	this->StartGame();

	this->_targetTowersCount = this->GetAllTowersCount();
	this->_playerController->ToggleEnabledInputState(false);

	FTimerHandle timerHandle;
	FTimerDelegate timerDelegate = FTimerDelegate::CreateUObject(this->_playerController, &AToonTanksPlayerController::ToggleEnabledInputState, true);
	this->GetWorldTimerManager().SetTimer(timerHandle, timerDelegate, this->_startGameDelay, false);
}

int AToonTanksGameMode::GetAllTowersCount() const
{
	TArray<AActor*> towers;
	UGameplayStatics::GetAllActorsOfClass(this, this->_towerBlueprint, towers);

	return towers.Num();
}