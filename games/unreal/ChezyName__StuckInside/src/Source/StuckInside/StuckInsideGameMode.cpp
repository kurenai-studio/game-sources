// Copyright Epic Games, Inc. All Rights Reserved.

#include "StuckInsideGameMode.h"

#include "EngineUtils.h"
#include "StuckInsideHUD.h"
#include "StuckInsideCharacter.h"
#include "StuckInsideGS.h"
#include "GameFramework/PlayerState.h"
#include "Kismet/GameplayStatics.h"
#include "UObject/ConstructorHelpers.h"

void AStuckInsideGameMode::ResetGame()
{
	GameStarted = false;
	SIGameState->currentTime = 0;
	//SIGameState->DemonPlayer = nullptr;
	//SIGameState->HumanPlayers = TArray<APlayerState*>();
	SIGameState->PowerActive = true;
	SIGameState->PowerUsage = 0;

	for(AWindowShutters* Window : Windows)
	{
		if(Window) Window->Close();
	}

	for(ASwitch* s : BreakerSwitches) s->activate();
	BreakerDoor->Close();

	for (ADoor* Door : TActorRange<ADoor>(GetWorld()))
	{
		if(Door)
		{
			UStaticMeshComponent* DoorMesh = Door->GetDoor();
			DoorMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			DoorMesh->SetVisibility(true);
		}
	}

	TArray<APlayerController*> Players;
	for (APlayerController* Controller : TActorRange<APlayerController>(GetWorld()))
	{
		if(Controller)
		{
			GEngine->AddOnScreenDebugMessage(-1,25,FColor::Yellow, Controller->GetName()
				+ " - " + Controller->GetPawn()->GetName());
			Players.Add(Controller);

			APawn* NewChar = Cast<APawn>(UGameplayStatics::BeginDeferredActorSpawnFromClass(GetWorld(),LobbyClass,FTransform(FRotator::ZeroRotator,FindPlayerStart(Controller,"None") ? FindPlayerStart(Controller,"None")->GetActorLocation() : FVector::ZeroVector),ESpawnActorCollisionHandlingMethod::AlwaysSpawn,Controller));
			if(NewChar != nullptr)
			{
				
				//Finalizing Create Projecitle
				if(Controller->GetPawn())
				{
					Controller->GetPawn()->Destroy();
				}
				Controller->Possess(NewChar);
				//Spawn The Actor
				UGameplayStatics::FinishSpawningActor(NewChar, FTransform(FRotator::ZeroRotator,FindPlayerStart(Controller,"None") ? FindPlayerStart(Controller,"None")->GetActorLocation() : FVector::ZeroVector));
			}
		}
	}

	EventResetGame(Players);
}

AStuckInsideGameMode::AStuckInsideGameMode()
	: Super()
{
	PrimaryActorTick.bStartWithTickEnabled = true;
	PrimaryActorTick.bCanEverTick = true;
	// set default pawn class to our Blueprinted character
	//static ConstructorHelpers::FClassFinder<APawn> PlayerPawnClassFinder(TEXT("/Game/FirstPersonCPP/Blueprints/FirstPersonCharacter"));
	//DefaultPawnClass = PlayerPawnClassFinder.Class;

	// use our custom HUD class
	//HUDClass = AStuckInsideHUD::StaticClass();
}

void AStuckInsideGameMode::onAllPlayersReady_Implementation()
{
	if(GameStarted) return;
	GameStarted = true;

	GEngine->AddOnScreenDebugMessage(-1,5,FColor::Green, "Game Is Starting Real Soon [C++]");

	//PlayersPick Spawn
	AStuckInsideGS* GS = Cast<AStuckInsideGS>(GameState);
	if(GS)
	{
		for (APlayerController* Controller : TActorRange<APlayerController>(GetWorld()))
		{
			GEngine->AddOnScreenDebugMessage(-1,5,FColor::Green, "Summoning " + Controller->GetName());
			//code
			if(Controller->GetPlayerState<APlayerState>() == GS->DemonPlayer)
			{
				//Spawn DEMON
				FActorSpawnParameters PlayerSpawnParameters{};
				APawn* NewChar = GetWorld()->SpawnActor<APawn>(Demon, FindPlayerStart(Controller,"Demon") ? FindPlayerStart(Controller,"Demon")->GetActorLocation() : FVector::ZeroVector, FRotator::ZeroRotator, PlayerSpawnParameters);
				if(Controller->GetPawn()) Controller->GetPawn()->Destroy();
				Controller->Possess(NewChar);
			}
			else
			{
				//Spawn HUMAN
				FActorSpawnParameters PlayerSpawnParameters{};
				APawn* NewChar = GetWorld()->SpawnActor<APawn>(Survivors, FindPlayerStart(Controller,"Human") ? FindPlayerStart(Controller,"Human")->GetActorLocation() : FVector::ZeroVector, FRotator::ZeroRotator, PlayerSpawnParameters);
				if(Controller->GetPawn()) Controller->GetPawn()->Destroy();
				Controller->Possess(NewChar);
			}
		}
	}
}

void AStuckInsideGameMode::HandleStartingNewPlayer_Implementation(APlayerController* NewPlayer)
{
    UE_LOG(LogTemp, Warning, TEXT("Spawning New player"));
	FVector StartLocation =  ChoosePlayerStart(NewPlayer) ? ChoosePlayerStart(NewPlayer)->GetActorLocation() : FVector::ZeroVector;
	if(GameStarted)
	{
		FActorSpawnParameters PlayerSpawnParameters{};
		APawn* NewChar = GetWorld()->SpawnActor<APawn>(DefaultPawnClass, StartLocation, FRotator::ZeroRotator, PlayerSpawnParameters);
		NewPlayer->Possess(NewChar);
	}
	else
	{
		FActorSpawnParameters PlayerSpawnParameters{};
		APawn* NewChar = GetWorld()->SpawnActor<APawn>(LobbyClass, StartLocation, FRotator::ZeroRotator, PlayerSpawnParameters);
		NewPlayer->Possess(NewChar);
	}
}

void AStuckInsideGameMode::BeginPlay()
{
	SIGameState = GetGameState<AStuckInsideGS>();
	//SetActorTickInterval(TickTime);
	if(GetWorld())
	{
		TArray<AActor*> FoundActorsA;
		UGameplayStatics::GetAllActorsOfClass(GetWorld(), AWindowShutters::StaticClass(), FoundActorsA);
		for(AActor* Actor : FoundActorsA)
		{
			AWindowShutters* w = Cast<AWindowShutters>(Actor);
			if(w)
			{
				Windows.Add(w);
			}
		}

		TArray<AActor*> FoundActorsB;
		UGameplayStatics::GetAllActorsOfClass(GetWorld(), ASwitch::StaticClass(), FoundActorsB);
		for(AActor* Actor : FoundActorsB)
		{
			ASwitch* s = Cast<ASwitch>(Actor);
			if(s)
			{
				BreakerSwitches.Add(s);
			}
		}

		BreakerDoor = Cast<ABreakerDoor>(UGameplayStatics::GetActorOfClass(GetWorld(), ABreakerDoor::StaticClass()));
	}
	Super::BeginPlay();
}

void AStuckInsideGameMode::KillPlayer(AStuckInsideCharacter* Character)
{
	AController* Controller = Character->GetController();
	Controller->UnPossess();
	Character->Destroy();
	
	FActorSpawnParameters PlayerSpawnParameters{};
	APawn* NewChar = GetWorld()->SpawnActor<APawn>(DefaultPawnClass, FindPlayerStart(Controller,"Human") ? FindPlayerStart(Controller,"Human")->GetActorLocation() : FVector::ZeroVector, FRotator::ZeroRotator, PlayerSpawnParameters);
	Controller->Possess(NewChar);
	
	TArray<AActor*> FoundActorsA;
	UGameplayStatics::GetAllActorsOfClass(GetWorld(), AStuckInsideCharacter::StaticClass(), FoundActorsA);
	if(FoundActorsA.Num() <= 0)
	{
		GEngine->AddOnScreenDebugMessage(-1,25,FColor::Red, "ALL PLAYERS DEAD!");
		if(SIGameState) SIGameState->DemonWon = true;
		ResetGame();
	}
}

void AStuckInsideGameMode::Tick(float DeltaSeconds)
{
	int WindowsActive = 0;
	for(AWindowShutters* Window : Windows)
	{
		if(IsValid(Window) && !Window->getIsOpened()) WindowsActive++;
	}

	GEngine->AddOnScreenDebugMessage(-1,0,FColor::Red,"Power Usage Time: " + FString::SanitizeFloat(Breaker));
	GEngine->AddOnScreenDebugMessage(-1,0,SIGameState->PowerActive ? FColor::Green : FColor::Red,"POWER");

	WindowsActive = FMath::Clamp(WindowsActive,0,3);
	if(SIGameState)
	{
		SIGameState->PowerUsage = WindowsActive;
		if(GameStarted) SIGameState->currentTime += DeltaSeconds;
		if(SIGameState->currentTime >= SIGameState->maxTime)
		{
			//Game Reset
			if(SIGameState) SIGameState->DemonWon = false;
			ResetGame();
		}
	}

	if(WindowsActive >= 3)
	{
		GEngine->AddOnScreenDebugMessage(-1,0,FColor::Red,"Power Depleting: " + FString::SanitizeFloat(Breaker));
		Breaker -= DeltaSeconds;
		if(SIGameState->PowerActive && Breaker <= 0)
		{
			//Turn Off Power
			SIGameState->PowerActive = false;

			for(AWindowShutters* Window : Windows)
			{
				if(Window) Window->Close();
			}

			for(ASwitch* s : BreakerSwitches) s->reset();
			BreakerDoor->Close();
		}
	}
	else
	{
		Breaker += DeltaSeconds;
	}

	//Power Checking
	bool SwitchIsOn = true;
	for(ASwitch* s : BreakerSwitches) if(IsValid(s) && !s->getSideActive()) SwitchIsOn = false;
	if(SwitchIsOn)
	{
		SIGameState->PowerActive = true;
	}
	else
	{
		//Turn Off Power
		SIGameState->PowerActive = false;
		Breaker = 0;

		for(AWindowShutters* Window : Windows)
		{
			Window->Close();
		}
	}

	Breaker = FMath::Clamp(Breaker,0.f,MaxPowerUsageTimeBeforeBreaker);
	Super::Tick(DeltaSeconds);
}
