// Fill out your copyright notice in the Description page of Project Settings.


#include "BattleBlasterGameMode.h"

#include "Camera/CameraActor.h"
#include "Kismet/GameplayStatics.h"
#include "Tower.h"
#include "EnemyTank.h"
#include "StartScreen.h"
#include "HealthPickup.h"


#include "BattleBlasterGameInstance.h"

void ABattleBlasterGameMode::BeginPlay()
{
	Super::BeginPlay();

	TArray<AActor*> Towers;
	UGameplayStatics::GetAllActorsOfClass(
		GetWorld(),
		ATower::StaticClass(),
		Towers
	);

	TowerCount = Towers.Num();

	APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);

	if (PlayerPawn)
	{
		Tank = Cast<ATank>(PlayerPawn);

		if (!Tank)
		{
			UE_LOG(
				LogTemp,
				Display,
				TEXT("GameMode: Failed to find the tank actor!")
			);
		}
	}

	for (AActor* TowerActor : Towers)
	{
		ATower* Tower = Cast<ATower>(TowerActor);

		if (Tower && Tank)
		{
			Tower->Tank = Tank;

			UE_LOG(
				LogTemp,
				Display,
				TEXT("%s setting the tank variable!"),
				*Tower->GetActorNameOrLabel()
			);
		}
	}

	TArray<AActor*> EnemyTanks;
	UGameplayStatics::GetAllActorsOfClass(
		GetWorld(),
		AEnemyTank::StaticClass(),
		EnemyTanks
	);

	TowerCount += EnemyTanks.Num();

	for (AActor* EnemyActor : EnemyTanks)
	{
		AEnemyTank* EnemyTank = Cast<AEnemyTank>(EnemyActor);

		if (EnemyTank && Tank)
		{
			EnemyTank->Tank = Tank;

			UE_LOG(
				LogTemp,
				Display,
				TEXT("%s setting the tank variable!"),
				*EnemyTank->GetActorNameOrLabel()
			);
		}
	}

	APlayerController* PlayerController =
		UGameplayStatics::GetPlayerController(GetWorld(), 0);

	if (PlayerController)
	{
		StartScreenWidget = CreateWidget<UStartScreen>(
			PlayerController,
			StartScreenClass
		);

		if (StartScreenWidget)
		{
			StartScreenWidget->AddToPlayerScreen();

			StartScreenWidget->OnFadeOutComplete.AddDynamic(
				this,
				&ABattleBlasterGameMode::OnStartScreenFadedOut
			);
		}

		IntroCameraTarget = UGameplayStatics::GetActorOfClass(
			GetWorld(),
			ACameraActor::StaticClass()
		);

		if (IntroCameraTarget)
		{
			PlayerController->SetViewTargetWithBlend(
				IntroCameraTarget,
				0.0f
			);
		}
	}
}

void ABattleBlasterGameMode::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	APlayerController* PlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0);

	if (bWaitingForFinalRestart)
	{
		if (PlayerController && PlayerController->WasInputKeyJustPressed(EKeys::Enter))
		{
			UBattleBlasterGameInstance* BattleBlasterGameInstance = Cast<UBattleBlasterGameInstance>(GetGameInstance());
			if (BattleBlasterGameInstance)
			{
				BattleBlasterGameInstance->RestartGame();
			}
		}
		return;
	}



	if (bGameStarted)
	{
		return;
	}

	if (PlayerController && PlayerController->WasInputKeyJustPressed(EKeys::Enter))
	{
		StartGame();
	}

}

ABattleBlasterGameMode::ABattleBlasterGameMode()
{
	PrimaryActorTick.bCanEverTick = true;
}

void ABattleBlasterGameMode::StartGame()
{
	bGameStarted = true;

	if (GameStartSound)
	{
		UGameplayStatics::PlaySound2D(GetWorld(), GameStartSound);
	}

	if (StartScreenWidget)
	{
		StartScreenWidget->PlayFadeOut();
	}

	APlayerController* PlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	if (PlayerController && Tank)
	{
		PlayerController->SetViewTargetWithBlend(Tank, CameraBlendTime);
	}

}


void ABattleBlasterGameMode::OnCountDownTimerTimeout()
{
	CountdownSeconds -= 1;

	if (CountdownSeconds > 0)
	{
		ScreenMessageWidget->SetMessageText(FString::FromInt(CountdownSeconds));
	}
	else if (CountdownSeconds == 0)
	{
		ScreenMessageWidget->SetMessageText(TEXT("GO!"));

		if (GoSound)
		{
			UGameplayStatics::PlaySound2D(GetWorld(), GoSound);
		}

		if (Tank)
		{
			Tank->SetPlayerEnabled(true);
		}
	}
	else
	{
		GetWorldTimerManager().ClearTimer(CountdownTimerHandle);

		ScreenMessageWidget->HideMessage();
	}
}

void ABattleBlasterGameMode::AddCombo()
{
	ComboCount++;

	GetWorldTimerManager().ClearTimer(ComboTimerHandle);

	GetWorldTimerManager().SetTimer(
		ComboTimerHandle,
		this,
		&ABattleBlasterGameMode::ResetCombo,
		ComboResetTime,
		false
	);

	UpdateComboMessage();

}

void ABattleBlasterGameMode::ResetCombo()
{
	ComboCount = 0;

	if (ScreenMessageWidget)
	{
		ScreenMessageWidget->HideCombo();
	}
}

void ABattleBlasterGameMode::UpdateComboMessage()
{
	if (!ScreenMessageWidget)
	{
		return;
	}

	if (ComboCount < 2)
	{
		ScreenMessageWidget->HideCombo();
		return;
	}

	FString ComboText = FString::Printf(TEXT("%dx COMBO!"), ComboCount);
	ScreenMessageWidget->SetComboText(ComboText);
}

void ABattleBlasterGameMode::OnStartScreenFadedOut()
{	
	GetWorldTimerManager().SetTimer(PostFadeTimerHandle, this, &ABattleBlasterGameMode::ShowGetReadyMessage, 1, false);
}

void ABattleBlasterGameMode::ShowGetReadyMessage()
{
	APlayerController* PlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0);

	if (PlayerController)
	{
		ScreenMessageWidget = CreateWidget<UScreenMessage>(PlayerController, ScreenMessageClass);
		if (ScreenMessageWidget)
		{
			ScreenMessageWidget->AddToPlayerScreen();
			ScreenMessageWidget->SetMessageText("Get Ready");
		}
	}

	CountdownSeconds = CountdownDelay;

	if (CountDownTickSound)
	{
		UGameplayStatics::PlaySound2D(GetWorld(), CountDownTickSound);
	}

	GetWorldTimerManager().SetTimer(CountdownTimerHandle, this, &ABattleBlasterGameMode::OnCountDownTimerTimeout, 1.0f, true);
}



void ABattleBlasterGameMode::ActorDied(AActor* DeadActor)
{
	bool IsGameOver = false;

	if (DeadActor == Tank)
	{
		Tank->HandleDestruction();

		ResetCombo();

		IsGameOver = true;
	}

	else if (AEnemyTank* DeadEnemyTank = Cast<AEnemyTank>(DeadActor))
	{

		FVector DeathLocation = DeadEnemyTank->GetActorLocation();
		FRotator DeathRotation = DeadEnemyTank->GetActorRotation();

		DeadEnemyTank->HandleDestruction();

		if (HealthPickupClass && FMath::FRand() <= HealthPickupDropChance)
		{
			GetWorld()->SpawnActor<AHealthPickup>(
				HealthPickupClass,
				DeathLocation,
				DeathRotation
			);
		}


		AddCombo();

		TowerCount--;

		if (TowerCount == 0)
		{
			IsGameOver = true;
			IsVictory = true;
		}
	}

	else
	{
		ATower* DeadTower = Cast<ATower>(DeadActor);
		if (DeadTower)
		{
			FVector DeathLocation = DeadTower->GetActorLocation();
			FRotator DeathRotation = DeadTower->GetActorRotation();

			DeadTower->HandleDestruction();

			if (HealthPickupClass && FMath::FRand() <= HealthPickupDropChance)
			{
				GetWorld()->SpawnActor<AHealthPickup>(
					HealthPickupClass,
					DeathLocation,
					DeathRotation
				);

			}


			AddCombo();

			TowerCount--;
			if (TowerCount == 0)
			{
				IsGameOver = true;
				IsVictory = true;
			}
		}
	}

	if (IsGameOver)
	{
		FString GameOverString = IsVictory ? "Victory!" : "Defeat!";
		FString ContinueMessage = "";

		bool bIsFinalLevelWin = false;

		if (IsVictory)
		{
			UBattleBlasterGameInstance* BattleBlasterGameInstance = Cast<UBattleBlasterGameInstance>(GetGameInstance());
			if (BattleBlasterGameInstance)
			{	

				if (BattleBlasterGameInstance->CurrentLevelIndex >= BattleBlasterGameInstance->LastLevelIndex)
				{
					bIsFinalLevelWin = true;
					GameOverString = "Game Won!!!!";
					ContinueMessage = "Press ENTER to continue";
				}
			}
		}

		if (IsVictory)
		{
			if (VictorySound)
			{
				UGameplayStatics::PlaySound2D(GetWorld(), VictorySound);
			}
		}
		else
		{
			if (DefeatSound)
			{
				UGameplayStatics::PlaySound2D(GetWorld(), DefeatSound);
			}
		}

		ScreenMessageWidget->SetVisibility(ESlateVisibility::Visible);
		ScreenMessageWidget->SetMessageText(GameOverString);
		ScreenMessageWidget->SetComboText(ContinueMessage);

		if (bIsFinalLevelWin)
		{
			bWaitingForFinalRestart = true;
		}
		else
		{
			FTimerHandle GameOverTimerHandle;
			GetWorldTimerManager().SetTimer(GameOverTimerHandle, this, &ABattleBlasterGameMode::OnGameOverTimerTimeout, GameOverDelay, false);
		}
	}
}

void ABattleBlasterGameMode::OnGameOverTimerTimeout()
{
	FString CurrentLevelName = UGameplayStatics::GetCurrentLevelName(GetWorld());

	UGameInstance* GameInstance = GetGameInstance();
	if (GameInstance)
	{
		UBattleBlasterGameInstance* BattleBlasterGameInstance = Cast<UBattleBlasterGameInstance>(GameInstance);
		if (BattleBlasterGameInstance)
		{
			if (IsVictory)
			{	
				// Load the next level
				BattleBlasterGameInstance->LoadNextLevel();
			}
			else
			{
				// Reload the current level
				UGameplayStatics::OpenLevel(GetWorld(), *CurrentLevelName);
				BattleBlasterGameInstance->RestartCurrentLevel();
			}
		}
	}
}
