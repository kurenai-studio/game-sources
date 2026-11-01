#include "Core/SeagullStormGameMode.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameState.h"
#include "Core/SeagullPlayerController.h"
#include "Player/SeagullPlayerPawn.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Horizon/SeagullStatisticsSession.h"
#include "UI/SeagullStatisticsPanel.h"
#include "Audio/SeagullAudioManager.h"
#include "Enemies/SeagullEnemySpawner.h"
#include "Map/SeagullMapGenerator.h"
#include "Weapons/SeagullWeaponManager.h"
#include "Weapons/SeagullWeaponBase.h"
#include "Weapons/SeagullWeapon_Feather.h"
#include "Weapons/SeagullWeapon_Screech.h"
#include "Weapons/SeagullWeapon_Dive.h"
#include "Weapons/SeagullWeapon_Gust.h"
#include "Data/SeagullConfigCache.h"
#include "UI/SeagullGameOverScreen.h"
#include "SeagullStorm.h"
#include "Kismet/GameplayStatics.h"
#include "EngineUtils.h"

ASeagullStormGameMode::ASeagullStormGameMode()
{
	PrimaryActorTick.bCanEverTick = true;

	DefaultPawnClass = nullptr; // No pawn on title/hub
	PlayerControllerClass = ASeagullPlayerController::StaticClass();
	GameStateClass = ASeagullStormGameState::StaticClass();
}

void ASeagullStormGameMode::BeginPlay()
{
	Super::BeginPlay();

	// Create audio manager
	AudioManager = NewObject<USeagullAudioManager>(this);
	AudioManager->Initialize();

	// Create enemy spawner
	EnemySpawner = NewObject<USeagullEnemySpawner>(this);

	// Connect to horizOn server
	USeagullHorizonManager* HM = GetHorizonManager();
	if (HM)
	{
		HM->ConnectToServer();
	}

	SwitchToScreen(ESeagullGameScreen::Title);
}

void ASeagullStormGameMode::RestoreSessionWhenConnected()
{
	// The SDK checks the cached session against the server, so wait until host selection has finished.
	USeagullHorizonManager* HM = GetHorizonManager();
	if (HM && (CurrentScreen != ESeagullGameScreen::Title || HM->IsSignedIn())) return; // The player already chose a way in.
	if (HM)
	{
		TWeakObjectPtr<ASeagullStormGameMode> WeakThis(this);
        HM->RestoreSession([WeakThis](bool bSuccess)
        {
            ASeagullStormGameMode* Self = WeakThis.Get();
            if (!Self || Self->CurrentScreen != ESeagullGameScreen::Title) return;
            USeagullGameInstance* GI = Self->GetSeagullGameInstance();
            if (!GI || GI->bPracticeMode) return;
			if (bSuccess)
			{
				GI->BeginOnlineSession();
				UE_LOG(LogSeagullStorm, Log, TEXT("Session restored, going to Hub"));
				Self->SwitchToScreen(ESeagullGameScreen::Hub);
			}
			else
			{
				UE_LOG(LogSeagullStorm, Log, TEXT("No session to restore, showing Title"));
				Self->SwitchToScreen(ESeagullGameScreen::Title);
			}
		});
	}
	else
	{
		SwitchToScreen(ESeagullGameScreen::Title);
	}
}

void ASeagullStormGameMode::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
    // Restore the session and register diagnostics only once the asynchronous host selection has completed.
    if (!bSessionRestoreStarted)
    {
        USeagullHorizonManager* HM = GetHorizonManager();
        if (!HM || HM->IsConnected())
        {
            bSessionRestoreStarted = true;
            RestoreSessionWhenConnected();
        }
    }
    if (!bCrashCaptureStarted)
    {
        USeagullHorizonManager* HM = GetHorizonManager();
        if (HM && HM->IsConnected())
        {
#if WITH_DEV_AUTOMATION_TESTS
            FString Fixture;
            if (!FParse::Value(FCommandLine::Get(), TEXT("SeagullFixture="), Fixture))
#endif
                HM->StartCrashCapture();
            bCrashCaptureStarted = true;
        }
    }

	if (CurrentScreen == ESeagullGameScreen::Run)
	{
		ASeagullStormGameState* GS = GetGameState<ASeagullStormGameState>();
		if (GS)
		{
			GS->TickTimer(DeltaTime);

			// Validated Actions: the input log keeps every change of the move stick.
			ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(
				UGameplayStatics::GetPlayerController(GetWorld(), 0));
			if (PC && GS->bRunActive)
			{
				const FVector2D Move = PC->GetMoveInput();
				InputLog.RecordMove(GS->RunStats.Duration, static_cast<float>(Move.X), static_cast<float>(Move.Y));
			}

			// Add survival time to score (Fix 12: 1 point per second)
			SurvivalScoreAccumulator += DeltaTime;
			if (SurvivalScoreAccumulator >= 1.0f)
			{
				int32 TimePoints = static_cast<int32>(SurvivalScoreAccumulator);
				GS->AddScore(TimePoints);
				SurvivalScoreAccumulator -= static_cast<float>(TimePoints);
			}

			if (GS->IsTimerExpired())
			{
				// Spawn boss or end run
				if (EnemySpawner && !GS->bBossSpawned)
				{
					GS->bBossSpawned = true;
					USeagullGameInstance* GI = GetSeagullGameInstance();
					bool bBossEnabled = true;
					if (GI && GI->GetConfigCache())
					{
						bBossEnabled = GI->GetConfigCache()->bBossWaveEnabled;
					}
					if (bBossEnabled)
					{
						EnemySpawner->SpawnBoss(GetWorld());
						// Switch to boss music
						if (AudioManager && AudioManager->MusicBoss)
						{
							AudioManager->CrossfadeToTrack(AudioManager->MusicBoss, GetWorld());
						}
					}
					else
					{
						EndRun(false);
					}
				}
			}
		}

		// Tick enemy spawner — stop spawning after timer expires / boss phase
		if (EnemySpawner && GS && !GS->bBossSpawned && !GS->IsTimerExpired())
		{
			EnemySpawner->Tick(DeltaTime, GetWorld());
		}
	}
}

void ASeagullStormGameMode::SwitchToScreen(ESeagullGameScreen NewScreen)
{
	if (NewScreen == ESeagullGameScreen::Title)
	{
		++RunSerial;
		bAwaitingRunTicket = false;
		if (USeagullHorizonManager* HM = GetHorizonManager()) HM->DiscardValidatedRun();
	}
	ESeagullGameScreen OldScreen = CurrentScreen;
	CurrentScreen = NewScreen;

	UE_LOG(LogSeagullStorm, Log, TEXT("Screen transition: %d -> %d"), static_cast<int32>(OldScreen), static_cast<int32>(NewScreen));

	// Notify controller to swap UI
	ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(
		UGameplayStatics::GetPlayerController(GetWorld(), 0));
	if (PC)
	{
		PC->OnScreenChanged(NewScreen);
	}

	// Music transitions
	if (AudioManager)
	{
		switch (NewScreen)
		{
			case ESeagullGameScreen::Title:
			case ESeagullGameScreen::Hub:
				AudioManager->CrossfadeToTrack(AudioManager->MusicMenu, GetWorld());
				break;
			case ESeagullGameScreen::Run:
				AudioManager->CrossfadeToTrack(AudioManager->MusicBattle, GetWorld());
				break;
			case ESeagullGameScreen::GameOver:
				AudioManager->CrossfadeToTrack(AudioManager->MusicMenu, GetWorld());
				if (AudioManager->SFX_GameOver)
				{
					AudioManager->PlaySFX(AudioManager->SFX_GameOver, GetWorld());
				}
				break;
		}
	}

	// Record breadcrumb
	USeagullHorizonManager* HM = GetHorizonManager();
	if (HM)
	{
		FString ScreenName;
		switch (NewScreen)
		{
			case ESeagullGameScreen::Title: ScreenName = TEXT("title"); break;
			case ESeagullGameScreen::Hub: ScreenName = TEXT("hub"); break;
			case ESeagullGameScreen::Run: ScreenName = TEXT("run"); break;
			case ESeagullGameScreen::GameOver: ScreenName = TEXT("game_over"); break;
		}
		HM->RecordBreadcrumb(TEXT("navigation"), FString::Printf(TEXT("entered_%s"), *ScreenName));
	}

	OnScreenChanged.Broadcast(NewScreen);
}

void ASeagullStormGameMode::StartRun()
{
    if (bAwaitingRunTicket || CurrentScreen == ESeagullGameScreen::Run) return;
    USeagullGameInstance* PendingGI=GetSeagullGameInstance(); auto* PendingHM=GetHorizonManager();
    if (PendingGI && !PendingGI->bPracticeMode && PendingHM && PendingHM->IsSignedIn() && !PendingGI->GetStatisticsSession()->CanStartOnlineRound())
    {
        RunStatus=PendingGI->GetStatisticsSession()->GetStatus();
        if (auto* PC=Cast<APlayerController>(UGameplayStatics::GetPlayerController(GetWorld(),0))) if (auto* Panel=CreateWidget<USeagullStatisticsPanel>(PC)) Panel->AddToViewport(100);
        return;
    }
    CachedGameOverWidget = nullptr;
    ScoreStatus.Empty();
    CleanupRunActors();
    SurvivalScoreAccumulator = 0.f;
    USeagullGameInstance* GI = GetSeagullGameInstance();
    // A late cloud response must not rewind upgrades acquired during this run.
    if (GI) GI->bSaveLoaded = true;
    BeginValidatedRun();
}

void ASeagullStormGameMode::SetupRunActors()
{
    USeagullGameInstance* GI = GetSeagullGameInstance();
    ASeagullStormGameState* GS = GetGameState<ASeagullStormGameState>();
    if (GS)
    {
        GS->InitRun(GI ? GI->GetConfigCache() : nullptr);
        GS->OnTriggerLevelUpChoices.AddUniqueDynamic(this, &ASeagullStormGameMode::OnLevelUpTriggered);
    }
	// Reset enemy spawner
	if (EnemySpawner)
	{
		EnemySpawner->Initialize(GI ? GI->GetConfigCache() : nullptr);
	}

	// Spawn map generator (Fix 8)
	if (GetWorld())
	{
		FActorSpawnParameters MapParams;
		MapParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		GetWorld()->SpawnActor<ASeagullMapGenerator>(ASeagullMapGenerator::StaticClass(),
			FVector::ZeroVector, FRotator::ZeroRotator, MapParams);
	}

	// Spawn player pawn and possess (Fix 8)
	if (GetWorld())
	{
		FActorSpawnParameters PawnParams;
		PawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		ASeagullPlayerPawn* Pawn = GetWorld()->SpawnActor<ASeagullPlayerPawn>(
			ASeagullPlayerPawn::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, PawnParams);

		if (Pawn)
		{
			ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(
				UGameplayStatics::GetPlayerController(GetWorld(), 0));
			if (PC)
			{
				PC->Possess(Pawn);
			}

			// Initialize weapon stats from config (Fix 9)
			if (GI && GI->GetConfigCache() && Pawn->WeaponManager)
			{
				USeagullConfigCache* Config = GI->GetConfigCache();
				USeagullWeaponBase* FeatherBase = Pawn->WeaponManager->GetWeapon(ESeagullWeaponType::Feather);
				if (FeatherBase)
				{
					FeatherBase->SetStats(Config->FeatherStats.Damage, Config->FeatherStats.Cooldown);
					USeagullWeapon_Feather* Feather = Cast<USeagullWeapon_Feather>(FeatherBase);
					if (Feather) Feather->ProjectileCount = Config->FeatherStats.Projectiles;
				}

				USeagullWeaponBase* ScreechBase = Pawn->WeaponManager->GetWeapon(ESeagullWeaponType::Screech);
				if (ScreechBase)
				{
					ScreechBase->SetStats(Config->ScreechStats.Damage, Config->ScreechStats.Cooldown);
					USeagullWeapon_Screech* Screech = Cast<USeagullWeapon_Screech>(ScreechBase);
					if (Screech) Screech->Radius = Config->ScreechStats.Range;
				}

				USeagullWeaponBase* DiveBase = Pawn->WeaponManager->GetWeapon(ESeagullWeaponType::Dive);
				if (DiveBase)
				{
					DiveBase->SetStats(Config->DiveStats.Damage, Config->DiveStats.Cooldown);
					USeagullWeapon_Dive* Dive = Cast<USeagullWeapon_Dive>(DiveBase);
					if (Dive) Dive->Range = Config->DiveStats.Range;
				}

				USeagullWeaponBase* GustBase = Pawn->WeaponManager->GetWeapon(ESeagullWeaponType::Gust);
				if (GustBase)
				{
					GustBase->SetStats(Config->GustStats.Damage, Config->GustStats.Cooldown);
					USeagullWeapon_Gust* Gust = Cast<USeagullWeapon_Gust>(GustBase);
					if (Gust) Gust->KnockbackForce = Config->GustStats.Knockback;
				}

				// Store config in WeaponManager for mid-run unlocks
				Pawn->WeaponManager->ConfigCacheRef = Config;
			}
		}
	}

	SwitchToScreen(ESeagullGameScreen::Run);
}

void ASeagullStormGameMode::EndRun(bool bPlayerDied)
{
	ASeagullStormGameState* GS = GetGameState<ASeagullStormGameState>();
	USeagullGameInstance* GI = GetSeagullGameInstance();
	USeagullHorizonManager* HM = GetHorizonManager();
    if (!GS || !GS->bRunActive) return;
    GS->bRunActive = false;
    SwitchToScreen(ESeagullGameScreen::GameOver);

    if (GS && GI)
	{
		// Calculate coins
		int32 CoinDivisor = 10;
		if (GI->GetConfigCache())
		{
			CoinDivisor = FMath::Max(1, GI->GetConfigCache()->CoinDivisor);
		}
		int32 CoinsEarned = GS->CurrentScore / CoinDivisor;
		GS->RunStats.CoinsEarned = CoinsEarned;

		// Update save data
		GI->SaveData.Coins += CoinsEarned;
		GI->SaveData.TotalRuns++;
		if (GS->CurrentScore > GI->SaveData.Highscore)
		{
			GI->SaveData.Highscore = GS->CurrentScore;
		}

		// Track wave-1 deaths
		if (bPlayerDied && GS->CurrentWave <= 1)
		{
			GI->ConsecutiveWave1Deaths++;
			if (GI->ConsecutiveWave1Deaths >= 3 && HM)
			{
				HM->LogWarn(TEXT("Player died in wave 1 three consecutive times - possible balancing issue"));
				GI->ConsecutiveWave1Deaths = 0;
			}
		}
		else
		{
			GI->ConsecutiveWave1Deaths = 0;
		}

		// Submit to horizOn
		if (CachedGameOverWidget) CachedGameOverWidget->LoadGameOverData();
		GI->PersistPracticeSave();

		if (HM)
		{
            if (!bRunPractice && !GI->bPracticeMode && HM->IsSignedIn()) GI->GetStatisticsSession()->RecordRound(GS->RunStats.Kills,GS->CurrentScore);
			SubmitRunScore(HM, GS->CurrentScore, GS->CurrentWave, CoinsEarned, GS->RunStats.Duration);

			const uint64 SaveGeneration = GI->SessionGeneration;
			const FString SaveOwner = GI->SaveOwnerId;
			TWeakObjectPtr<USeagullGameInstance> WeakSaveGI(GI);
			TWeakObjectPtr<USeagullHorizonManager> WeakSaveHM(HM);
			if (!bRunPractice && !GI->bPracticeMode && HM->IsSignedIn() && GI->bCloudSaveReady) HM->SaveData(GI->SaveData.ToJsonString(), [WeakSaveGI, WeakSaveHM, SaveGeneration, SaveOwner](bool bSaveSuccess)
			{
				USeagullGameInstance* Instance = WeakSaveGI.Get();
				USeagullHorizonManager* Manager = WeakSaveHM.Get();
				if (!Instance || !Manager || Instance->SessionGeneration != SaveGeneration || Instance->SaveOwnerId != SaveOwner || Instance->bPracticeMode) return;
				if (!bSaveSuccess)
				{
					Manager->RecordException(
						TEXT("SaveData failed"),
						TEXT("CloudSave SaveData returned bSuccess=false at EndRun"));
				}
			});

			// User log
			FString LogMsg = FString::Printf(
				TEXT("Run ended | Waves: %d | Level: %d | Score: %d | Duration: %dm%ds | Upgrades: speed:%d,dmg:%d,hp:%d,magnet:%d | Coins earned: %d"),
				GS->CurrentWave, GS->CurrentLevel, GS->CurrentScore,
				static_cast<int32>(GS->RunStats.Duration) / 60,
				static_cast<int32>(GS->RunStats.Duration) % 60,
				GI->SaveData.GetUpgradeLevel(TEXT("speed")),
				GI->SaveData.GetUpgradeLevel(TEXT("damage")),
				GI->SaveData.GetUpgradeLevel(TEXT("hp")),
				GI->SaveData.GetUpgradeLevel(TEXT("magnet")),
				CoinsEarned);
			if (!bRunPractice) HM->LogInfo(LogMsg);
		}
	}

	// Mark run as inactive so timer/spawner stop
	if (GS)
	{
		GS->bRunActive = false;
	}

	SurvivalScoreAccumulator = 0.f;
	CleanupRunActors();
	ShowScoreStatus(ScoreStatus, bScoreStatusError);
}

void ASeagullStormGameMode::ReturnToHub()
{
	CleanupRunActors();
	SwitchToScreen(ESeagullGameScreen::Hub);
}

void ASeagullStormGameMode::RecordLevelUpChoice(int32 ChoiceIndex)
{
	ASeagullStormGameState* GS = GetGameState<ASeagullStormGameState>();
	if (GS && GS->bRunActive)
	{
		InputLog.RecordLevelUpChoice(GS->RunStats.Duration, ChoiceIndex);
	}
}

void ASeagullStormGameMode::BeginValidatedRun()
{
    InputLog.Reset();
    bValidatedTicketReady = false;
    bAwaitingRunTicket = false;
    bRunPractice = true;
    bAllowNormalSubmit = false;
    ++RunSerial;
    USeagullHorizonManager* HM = GetHorizonManager();
    USeagullGameInstance* GI = GetSeagullGameInstance();
    if (HM) HM->DiscardValidatedRun();
    if (!HM || !GI || GI->bPracticeMode || !HM->IsSignedIn())
    {
        RunStatus = TEXT("Practice / score stays local");
        SetupRunActors();
        return;
    }
    if (!GI->GetConfigCache()->bValidatedActionsEnabled)
    {
        bRunPractice = false;
        bAllowNormalSubmit = true;
        RunStatus = TEXT("Online / ordinary leaderboard");
        SetupRunActors();
        return;
    }
    bAwaitingRunTicket = true;
    RunStatus = TEXT("Requesting ranked run ticket...");
    const int32 Serial = RunSerial;
    TWeakObjectPtr<ASeagullStormGameMode> WeakThis(this);
    HM->StartValidatedRun(GI->GetConfigCache()->ValidatedRunsBoard,
        [WeakThis, Serial](bool bSuccess, int32 Seed, const FString& ErrorCode)
        {
            ASeagullStormGameMode* GM = WeakThis.Get();
            if (!GM || Serial != GM->RunSerial) return;
            GM->bAwaitingRunTicket = false;
            if (bSuccess)
            {
                FMath::RandInit(Seed);
                GM->InputLog.SetSeed(Seed);
                GM->bValidatedTicketReady = true;
                GM->bRunPractice = false;
                GM->RunStatus = TEXT("Online / ticket received / result pending");
            }
            else
            {
                if (USeagullGameInstance* GI = GM->GetSeagullGameInstance()) GI->BeginPractice();
				GM->RunStatus = FString::Printf(TEXT("Practice / %s"), *USeagullHorizonManager::DescribeScoreError(ErrorCode));
            }
            GM->SetupRunActors();
        });
}

void ASeagullStormGameMode::SubmitRunScore(USeagullHorizonManager* HM, int32 Score, int32 Wave, int32 CoinsEarned, float RunSeconds)
{
	TWeakObjectPtr<ASeagullStormGameMode> WeakThis(this);
    const int32 Serial = RunSerial;
    if (bRunPractice)
    {
        ShowScoreStatus(TEXT("Practice complete / local progress / no leaderboard submission"), false);
        return;
    }
    ShowScoreStatus(TEXT("Submitting run / waiting for server..."), false);

    if (bValidatedTicketReady && HM->HasValidatedRun())
	{
		bValidatedTicketReady = false;
		InputLog.Finish(RunSeconds);
		if (InputLog.IsTruncated())
		{
			HM->DiscardValidatedRun();
			ShowScoreStatus(TEXT("Input evidence limit reached / score not submitted"), true);
			return;
		}

		// Stage "wave_N" lets the dashboard rules set limits per wave. Coins go along as an
		// earned value only when the remote config names the value key of the rules.
		USeagullGameInstance* GI = GetSeagullGameInstance();
		const FString CoinsKey = (GI && GI->GetConfigCache()) ? GI->GetConfigCache()->ValidatedCoinsKey : FString();
		const FString Stage = FString::Printf(TEXT("wave_%d"), Wave);

		// The SDK hashes the log and, when the server asks for it, uploads it as evidence.
		HM->SubmitValidatedScore(static_cast<int64>(Score), InputLog.GetBytes(), Stage, CoinsKey, CoinsEarned,
			[WeakThis, HM, Serial](bool bSuccess, int64 Rank, const FString& ErrorCode)
			{
				ASeagullStormGameMode* GM = WeakThis.Get();
				if (!GM || Serial != GM->RunSerial) return;

				if (bSuccess)
				{
					if (Rank > 0 && GM->CachedGameOverWidget)
					{
						GM->CachedGameOverWidget->SetRank(static_cast<int32>(Rank));
					}
					GM->ShowScoreStatus(TEXT("Server accepted / validated score submitted"), false);
					return;
				}

				UE_LOG(LogSeagullStorm, Warning, TEXT("Validated run rejected: %s"), *ErrorCode);
				HM->LogWarn(FString::Printf(TEXT("Validated run rejected: %s"), *ErrorCode));
				GM->ShowScoreStatus(USeagullHorizonManager::DescribeScoreError(ErrorCode), true);
			});
		return;
	}

	if (!bAllowNormalSubmit)
    {
        ShowScoreStatus(TEXT("Practice / no valid ticket / score stays local"), true);
        return;
    }
    // Ordinary board explicitly selected through remote config; never labeled validated.
	HM->SubmitScore(static_cast<int64>(Score), [WeakThis, HM, Serial](bool bScoreSuccess)
	{
		ASeagullStormGameMode* SubmitGM = WeakThis.Get();
        if (!SubmitGM || Serial != SubmitGM->RunSerial) return;
        if (bScoreSuccess)
        {
            SubmitGM->ShowScoreStatus(TEXT("Ordinary score submitted / no validation"), false);
			// After score is submitted, fetch rank
			HM->GetRank([WeakThis, Serial](bool bRankSuccess, const FHorizonLeaderboardEntry& Entry)
			{
				ASeagullStormGameMode* RankGM = WeakThis.Get();
				if (bRankSuccess && RankGM && Serial == RankGM->RunSerial && RankGM->CachedGameOverWidget)
				{
					RankGM->CachedGameOverWidget->SetRank(Entry.Position);
				}
			});
			return;
		}

		// A "validated only" board refuses the normal submit: tell the player why.
		const FString ErrorCode = HM->GetLastSubmitErrorCode();
		ASeagullStormGameMode* GM = WeakThis.Get();
		if (GM)
		{
			GM->ShowScoreStatus(USeagullHorizonManager::DescribeScoreError(ErrorCode), true);
			return;
		}

		HM->RecordException(
			TEXT("SubmitScore failed"),
			TEXT("SubmitScore returned bSuccess=false at EndRun"));
	});
}

void ASeagullStormGameMode::ShowScoreStatus(const FString& Message, bool bIsError)
{
	ScoreStatus = Message;
	bScoreStatusError = bIsError;
	if (CachedGameOverWidget)
	{
		CachedGameOverWidget->SetScoreStatus(Message, bIsError);
	}
}

USeagullGameInstance* ASeagullStormGameMode::GetSeagullGameInstance() const
{
	return Cast<USeagullGameInstance>(GetGameInstance());
}

USeagullHorizonManager* ASeagullStormGameMode::GetHorizonManager() const
{
	USeagullGameInstance* GI = GetSeagullGameInstance();
	return GI ? GI->GetHorizonManager() : nullptr;
}

void ASeagullStormGameMode::OnLevelUpTriggered()
{
	ASeagullStormGameState* GS = GetGameState<ASeagullStormGameState>();
	if (!GS) return;

	TArray<FSeagullLevelUpChoice> Choices = GS->GetLevelUpChoices(3);
	if (Choices.Num() == 0) return;

	ASeagullPlayerController* PC = Cast<ASeagullPlayerController>(
		UGameplayStatics::GetPlayerController(GetWorld(), 0));
	if (PC)
	{
		PC->ShowLevelUpOverlay(Choices);
	}

	// Breadcrumb for level-up event (Fix 11)
	USeagullHorizonManager* HM = GetHorizonManager();
	if (HM)
	{
		HM->RecordBreadcrumb(TEXT("state"), FString::Printf(TEXT("level_%d"), GS->CurrentLevel));
		HM->SetCrashCustomKey(TEXT("level"), FString::FromInt(GS->CurrentLevel));
		HM->SetCrashCustomKey(TEXT("score"), FString::FromInt(GS->CurrentScore));
	}

	// Play level-up SFX (Fix 6)
	if (AudioManager && AudioManager->SFX_LevelUp)
	{
		AudioManager->PlaySFX(AudioManager->SFX_LevelUp, GetWorld());
	}
}

void ASeagullStormGameMode::CleanupRunActors()
{
	// Destroy all enemies, pickups, projectiles
	if (GetWorld())
	{
		TArray<AActor*> ToDestroy;
		for (TActorIterator<AActor> It(GetWorld()); It; ++It)
		{
			AActor* Actor = *It;
			if (Actor && (Actor->Tags.Contains(TEXT("Enemy")) ||
				Actor->Tags.Contains(TEXT("Pickup")) ||
				Actor->Tags.Contains(TEXT("Projectile")) ||
				Actor->Tags.Contains(TEXT("PlayerPawn")) ||
				Actor->IsA<ASeagullMapGenerator>()))
			{
				ToDestroy.Add(Actor);
			}
		}
		for (AActor* Actor : ToDestroy)
		{
			Actor->Destroy();
		}
	}
}
