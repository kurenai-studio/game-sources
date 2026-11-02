#pragma once

#include <vector>

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Rules/Dash.h"
#include "Rules/RunState.h"
#include "Rules/Spawner.h"
#include "Rules/Vec2.h"
#include "CoinRunDirector.generated.h"

class ACoinRunPawn;
class AStaticMeshActor;
class UMaterialInterface;
class UStaticMesh;

/**
 * Runs the game. Each tick it reads the keyboard, advances the engine-free rules (Source/CoinRun/Rules),
 * and moves plain mesh actors to match. Collision is circle-vs-circle in the rules, not Unreal physics,
 * so what the tests check is what the game does.
 */
UCLASS()
class COINRUN_API ACoinRunDirector : public AActor
{
	GENERATED_BODY()

public:
	ACoinRunDirector();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	// Read-only view for the HUD.
	const coinrun::RunState& GetRunState() const { return State; }
	const coinrun::Dash& GetDash() const { return DashState; }
	int32 GetBestScore() const { return BestScore; }
	bool IsNewBest() const { return bNewBest; }
	bool IsPaused() const { return bPaused; }
	float GetRunTime() const { return RunTime; }

private:
	struct FDrifter
	{
		coinrun::Vec2 Position;
		coinrun::Vec2 Direction;
		float Radius = 0.0f;
	};

	void BuildWorld();
	void StartRun();
	void FinishRun();
	AStaticMeshActor* SpawnShape(UStaticMesh* Mesh, const FVector& Location, const FVector& Scale, const FLinearColor& Color);
	void SpawnCoin();
	void SpawnDrifter();
	void UpdateCoins();
	void UpdateDrifters(float Dt);
	void SyncPlayer();
	void ClearEntities();

	coinrun::RunState State;
	coinrun::Dash DashState;
	TUniquePtr<coinrun::Spawner> Spawner;
	coinrun::Vec2 PlayerPosition;
	coinrun::Vec2 LastDirection = coinrun::Vec2(1.0f, 0.0f);

	// Rules-side data and the actors that show it live in parallel arrays (same index).
	std::vector<coinrun::Vec2> CoinPositions;
	std::vector<FDrifter> Drifters;

	UPROPERTY()
	TArray<TObjectPtr<AStaticMeshActor>> CoinActors;

	UPROPERTY()
	TArray<TObjectPtr<AStaticMeshActor>> DrifterActors;

	UPROPERTY()
	TObjectPtr<UStaticMesh> SphereMesh;

	UPROPERTY()
	TObjectPtr<UStaticMesh> CubeMesh;

	UPROPERTY()
	TObjectPtr<UMaterialInterface> BaseMaterial;

	TWeakObjectPtr<ACoinRunPawn> PlayerPawn;

	int32 BestScore = 0;
	bool bNewBest = false;
	bool bPaused = false;
	bool bWorldBuilt = false;
	float RunTime = 0.0f;
};
