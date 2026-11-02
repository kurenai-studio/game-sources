#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "CoinRunGameMode.generated.h"

/** Picks the pawn and HUD, then spawns the director that runs the game. Set as the project's default game mode in DefaultEngine.ini. */
UCLASS()
class COINRUN_API ACoinRunGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	ACoinRunGameMode();

	virtual void StartPlay() override;
};
