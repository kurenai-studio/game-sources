#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "PingPongGameMode.generated.h"

UCLASS()
class PINGPONG_API APingPongGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	APingPongGameMode();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	// Game state — read by HUD each frame
	FVector2D BallPos;       // normalized [0..1]
	FVector2D BallVel;       // normalized units/second
	float PlayerPaddleY;     // normalized center Y [0..1]
	float AIPaddleY;         // normalized center Y [0..1]

	// Constants
	static constexpr float PaddleH      = 0.18f;
	static constexpr float PaddleW      = 0.015f;
	static constexpr float BallRadius   = 0.012f;
	static constexpr float PaddleX      = 0.04f;    // X center of each paddle from its edge
	static constexpr float BallSpeed    = 0.45f;
	static constexpr float MaxBallSpeed = 0.90f;    // speed cap after many rally hits
	static constexpr float PaddleSpeed  = 0.70f;
	static constexpr float AISpeed      = 0.42f;

	// Rally state — read by HUD to show intensity (optional)
	int32 RallyCount;
	float CurrentBallSpeed;

private:
	void ResetBall();
	bool CheckPaddleCollision(float PaddleCX, float PaddleCY);
};
