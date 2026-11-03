#include "PingPongGameMode.h"
#include "PingPongPlayerController.h"
#include "PingPongHUD.h"
#include "Kismet/GameplayStatics.h"
#include "Math/UnrealMathUtility.h"

APingPongGameMode::APingPongGameMode()
{
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.bStartWithTickEnabled = true;

	PlayerControllerClass = APingPongPlayerController::StaticClass();
	HUDClass = APingPongHUD::StaticClass();

	PlayerPaddleY    = 0.5f;
	AIPaddleY        = 0.5f;
	RallyCount       = 0;
	CurrentBallSpeed = BallSpeed;
}

void APingPongGameMode::BeginPlay()
{
	Super::BeginPlay();

	if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
	{
		FInputModeGameOnly InputMode;
		PC->SetInputMode(InputMode);
		PC->bShowMouseCursor = false;
	}

	ResetBall();
}

void APingPongGameMode::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// --- Player input ---
	float MoveInput = 0.f;
	if (APingPongPlayerController* PC = Cast<APingPongPlayerController>(
		UGameplayStatics::GetPlayerController(this, 0)))
	{
		MoveInput = PC->GetMoveAxis();
	}

	PlayerPaddleY = FMath::Clamp(
		PlayerPaddleY + MoveInput * PaddleSpeed * DeltaTime,
		PaddleH * 0.5f, 1.f - PaddleH * 0.5f);

	// --- AI paddle ---
	float AIDir = FMath::Sign(BallPos.Y - AIPaddleY);
	AIPaddleY = FMath::Clamp(
		AIPaddleY + AIDir * AISpeed * DeltaTime,
		PaddleH * 0.5f, 1.f - PaddleH * 0.5f);

	// --- Ball movement ---
	BallPos += BallVel * DeltaTime;

	// Top / bottom wall bounce
	if (BallPos.Y - BallRadius <= 0.f)
	{
		BallPos.Y = BallRadius;
		BallVel.Y = FMath::Abs(BallVel.Y);
	}
	else if (BallPos.Y + BallRadius >= 1.f)
	{
		BallPos.Y = 1.f - BallRadius;
		BallVel.Y = -FMath::Abs(BallVel.Y);
	}

	// --- Paddle collisions ---
	// Left (player) paddle center
	if (BallVel.X < 0.f)
	{
		float PaddleCX = PaddleX + PaddleW * 0.5f;
		if (CheckPaddleCollision(PaddleCX, PlayerPaddleY))
		{
			++RallyCount;
			CurrentBallSpeed = FMath::Min(BallSpeed * FMath::Pow(1.08f, RallyCount), MaxBallSpeed);

			BallVel.X = FMath::Abs(BallVel.X);
			float HitOffset = (BallPos.Y - PlayerPaddleY) / (PaddleH * 0.5f);
			BallVel.Y = HitOffset * CurrentBallSpeed * 0.8f;
			BallVel = BallVel.GetSafeNormal() * CurrentBallSpeed;
		}
	}
	// Right (AI) paddle center
	if (BallVel.X > 0.f)
	{
		float PaddleCX = 1.f - PaddleX - PaddleW * 0.5f;
		if (CheckPaddleCollision(PaddleCX, AIPaddleY))
		{
			++RallyCount;
			CurrentBallSpeed = FMath::Min(BallSpeed * FMath::Pow(1.08f, RallyCount), MaxBallSpeed);

			BallVel.X = -FMath::Abs(BallVel.X);
			float HitOffset = (BallPos.Y - AIPaddleY) / (PaddleH * 0.5f);
			BallVel.Y = HitOffset * CurrentBallSpeed * 0.8f;
			BallVel = BallVel.GetSafeNormal() * CurrentBallSpeed;
		}
	}

	// --- Out of bounds — reset ---
	if (BallPos.X < 0.f || BallPos.X > 1.f)
	{
		ResetBall();
	}
}

bool APingPongGameMode::CheckPaddleCollision(float PaddleCX, float PaddleCY)
{
	float HalfW = PaddleW * 0.5f + BallRadius;
	float HalfH = PaddleH * 0.5f + BallRadius;
	return FMath::Abs(BallPos.X - PaddleCX) <= HalfW &&
	       FMath::Abs(BallPos.Y - PaddleCY) <= HalfH;
}

void APingPongGameMode::ResetBall()
{
	BallPos          = FVector2D(0.5f, 0.5f);
	RallyCount       = 0;
	CurrentBallSpeed = BallSpeed;

	// Pick a random quadrant angle: 30-60, 120-150, 210-240, 300-330 degrees
	static const float Sectors[4] = { 30.f, 120.f, 210.f, 300.f };
	float BaseDeg  = Sectors[FMath::RandRange(0, 3)];
	float AngleDeg = BaseDeg + FMath::FRandRange(0.f, 30.f);
	float AngleRad = FMath::DegreesToRadians(AngleDeg);

	BallVel = FVector2D(FMath::Cos(AngleRad), FMath::Sin(AngleRad)) * BallSpeed;
}
