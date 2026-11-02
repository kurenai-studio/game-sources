#include "Game/CoinRunDirector.h"

#include "Components/LightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "Game/CoinRunPawn.h"
#include "GameFramework/PlayerController.h"
#include "InputCoreTypes.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Misc/ConfigCacheIni.h"
#include "Rules/HighScore.h"
#include "Rules/Motion.h"
#include "Rules/Tuning.h"
#include "UObject/ConstructorHelpers.h"

namespace ct = coinrun::tuning;

namespace
{
	// The engine's basic shapes are 100 cm across.
	constexpr float kShapeSize = 100.0f;

	const TCHAR* kConfigSection = TEXT("CoinRun");
	const TCHAR* kConfigBestKey = TEXT("BestScore");
}

ACoinRunDirector::ACoinRunDirector()
{
	PrimaryActorTick.bCanEverTick = true;

	static ConstructorHelpers::FObjectFinder<UStaticMesh> Sphere(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	static ConstructorHelpers::FObjectFinder<UStaticMesh> Cube(TEXT("/Engine/BasicShapes/Cube.Cube"));
	static ConstructorHelpers::FObjectFinder<UMaterialInterface> Material(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
	if (Sphere.Succeeded()) { SphereMesh = Sphere.Object; }
	if (Cube.Succeeded()) { CubeMesh = Cube.Object; }
	if (Material.Succeeded()) { BaseMaterial = Material.Object; }
}

void ACoinRunDirector::BeginPlay()
{
	Super::BeginPlay();
	BuildWorld();
	StartRun();
}

AStaticMeshActor* ACoinRunDirector::SpawnShape(UStaticMesh* Mesh, const FVector& Location, const FVector& Scale, const FLinearColor& Color)
{
	UWorld* World = GetWorld();
	if (World == nullptr || Mesh == nullptr)
	{
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AStaticMeshActor* Actor = World->SpawnActor<AStaticMeshActor>(Location, FRotator::ZeroRotator, Params);
	if (Actor == nullptr)
	{
		return nullptr;
	}

	UStaticMeshComponent* Component = Actor->GetStaticMeshComponent();
	Component->SetMobility(EComponentMobility::Movable);
	Component->SetStaticMesh(Mesh);
	Component->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Actor->SetActorScale3D(Scale);

	if (BaseMaterial)
	{
		UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(BaseMaterial, Actor);
		Material->SetVectorParameterValue(TEXT("Color"), Color);
		Component->SetMaterial(0, Material);
	}
	return Actor;
}

void ACoinRunDirector::BuildWorld()
{
	if (bWorldBuilt)
	{
		return;
	}
	bWorldBuilt = true;

	UWorld* World = GetWorld();
	if (World == nullptr)
	{
		return;
	}

	// Floor: a flat cube whose top face sits at Z = 0.
	const float Span = ct::kArenaHalfExtent * 2.0f;
	SpawnShape(CubeMesh, FVector(0.0f, 0.0f, -5.0f), FVector(Span / kShapeSize, Span / kShapeSize, 0.1f), FLinearColor(0.04f, 0.05f, 0.09f));

	// Four low walls just outside the arena so its edge is visible.
	const float Edge = ct::kArenaHalfExtent + 10.0f;
	const float Length = (Span + 40.0f) / kShapeSize;
	const FLinearColor WallColor(0.25f, 0.3f, 0.55f);
	SpawnShape(CubeMesh, FVector(Edge, 0.0f, 15.0f), FVector(0.2f, Length, 0.3f), WallColor);
	SpawnShape(CubeMesh, FVector(-Edge, 0.0f, 15.0f), FVector(0.2f, Length, 0.3f), WallColor);
	SpawnShape(CubeMesh, FVector(0.0f, Edge, 15.0f), FVector(Length, 0.2f, 0.3f), WallColor);
	SpawnShape(CubeMesh, FVector(0.0f, -Edge, 15.0f), FVector(Length, 0.2f, 0.3f), WallColor);

	// Sun. A spawned light has to be Movable to be changed at runtime.
	if (ADirectionalLight* Sun = World->SpawnActor<ADirectionalLight>(FVector(0.0f, 0.0f, 800.0f), FRotator(-55.0f, -35.0f, 0.0f)))
	{
		if (ULightComponent* Light = Sun->GetLightComponent())
		{
			Light->SetMobility(EComponentMobility::Movable);
			Light->SetIntensity(5.0f);
		}
	}
}

void ACoinRunDirector::ClearEntities()
{
	for (AStaticMeshActor* Actor : CoinActors)
	{
		if (Actor != nullptr) { Actor->Destroy(); }
	}
	for (AStaticMeshActor* Actor : DrifterActors)
	{
		if (Actor != nullptr) { Actor->Destroy(); }
	}
	CoinActors.Empty();
	DrifterActors.Empty();
	CoinPositions.clear();
	Drifters.clear();
}

void ACoinRunDirector::StartRun()
{
	ClearEntities();

	State.Reset();
	DashState.Reset();
	Spawner = MakeUnique<coinrun::Spawner>(static_cast<int>(FPlatformTime::Cycles() & 0x7fffffffu));
	PlayerPosition = coinrun::Vec2(0.0f, 0.0f);
	LastDirection = coinrun::Vec2(1.0f, 0.0f);
	bNewBest = false;
	bPaused = false;
	RunTime = 0.0f;

	FString Stored;
	GConfig->GetString(kConfigSection, kConfigBestKey, Stored, GGameUserSettingsIni);
	// TCHAR_TO_UTF8 returns a temporary converter, so it has to be consumed inside this one expression.
	BestScore = coinrun::highscore::Parse(std::string(TCHAR_TO_UTF8(*Stored)));

	SyncPlayer();
}

void ACoinRunDirector::FinishRun()
{
	bool bIsNew = false;
	BestScore = coinrun::highscore::Update(BestScore, State.Score(), &bIsNew);
	bNewBest = bIsNew;

	const std::string Text = coinrun::highscore::Format(BestScore);
	GConfig->SetString(kConfigSection, kConfigBestKey, UTF8_TO_TCHAR(Text.c_str()), GGameUserSettingsIni);
	GConfig->Flush(false, GGameUserSettingsIni);
}

void ACoinRunDirector::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	UWorld* World = GetWorld();
	APlayerController* Controller = World != nullptr ? World->GetFirstPlayerController() : nullptr;
	if (Controller == nullptr)
	{
		return;
	}
	if (!PlayerPawn.IsValid())
	{
		PlayerPawn = Cast<ACoinRunPawn>(Controller->GetPawn());
	}

	if (State.IsOver())
	{
		if (Controller->WasInputKeyJustPressed(EKeys::R) || Controller->WasInputKeyJustPressed(EKeys::SpaceBar) || Controller->WasInputKeyJustPressed(EKeys::Enter))
		{
			StartRun();
		}
		return;
	}

	if (Controller->WasInputKeyJustPressed(EKeys::P) || Controller->WasInputKeyJustPressed(EKeys::Escape))
	{
		bPaused = !bPaused;
	}
	if (bPaused)
	{
		return;
	}

	// Clamp hitches so nothing can jump through the player in one step.
	const float Dt = FMath::Min(DeltaSeconds, 0.05f);
	RunTime += Dt;

	// Keyboard: W/S move along world X (up the screen), A/D along world Y. Space dashes.
	coinrun::Vec2 Input(0.0f, 0.0f);
	if (Controller->IsInputKeyDown(EKeys::W) || Controller->IsInputKeyDown(EKeys::Up)) { Input.x += 1.0f; }
	if (Controller->IsInputKeyDown(EKeys::S) || Controller->IsInputKeyDown(EKeys::Down)) { Input.x -= 1.0f; }
	if (Controller->IsInputKeyDown(EKeys::D) || Controller->IsInputKeyDown(EKeys::Right)) { Input.y += 1.0f; }
	if (Controller->IsInputKeyDown(EKeys::A) || Controller->IsInputKeyDown(EKeys::Left)) { Input.y -= 1.0f; }

	DashState.Tick(Dt);
	if (Controller->WasInputKeyJustPressed(EKeys::SpaceBar))
	{
		DashState.TryStart();
	}

	const coinrun::Vec2 Direction = coinrun::MoveDirection(Input, LastDirection, DashState.IsActive());
	if (Direction.SqrLength() > 0.0f)
	{
		LastDirection = Direction;
	}
	const float Speed = DashState.IsActive() ? ct::kDashSpeed : ct::kPlayerSpeed;
	PlayerPosition = coinrun::StepPlayer(PlayerPosition, Direction, Speed, Dt, ct::kArenaHalfExtent, ct::kPlayerRadius);

	State.Tick(Dt);

	if (Spawner->ShouldSpawnCoin(Dt, static_cast<int>(CoinPositions.size())))
	{
		SpawnCoin();
	}
	if (Spawner->ShouldSpawnDrifter(Dt, State.Wave(), static_cast<int>(Drifters.size())))
	{
		SpawnDrifter();
	}

	UpdateCoins();
	UpdateDrifters(Dt);
	SyncPlayer();

	if (State.IsOver())
	{
		FinishRun();
	}
}

void ACoinRunDirector::SpawnCoin()
{
	const coinrun::Vec2 Position = Spawner->NextCoinPosition(PlayerPosition, ct::kArenaHalfExtent, ct::kMinCoinDistance);
	const float Diameter = ct::kCoinRadius * 2.0f / kShapeSize;
	AStaticMeshActor* Actor = SpawnShape(SphereMesh, FVector(Position.x, Position.y, ct::kCoinRadius), FVector(Diameter), FLinearColor(1.0f, 0.8f, 0.1f));
	CoinPositions.push_back(Position);
	CoinActors.Add(Actor);
}

void ACoinRunDirector::SpawnDrifter()
{
	const coinrun::DrifterSpawn Spawn = Spawner->NextDrifter(PlayerPosition, ct::kArenaHalfExtent, State.Wave());
	const float Diameter = Spawn.radius * 2.0f / kShapeSize;
	AStaticMeshActor* Actor = SpawnShape(SphereMesh, FVector(Spawn.position.x, Spawn.position.y, Spawn.radius), FVector(Diameter), FLinearColor(1.0f, 0.2f, 0.2f));

	FDrifter Drifter;
	Drifter.Position = Spawn.position;
	Drifter.Direction = Spawn.direction;
	Drifter.Radius = Spawn.radius;
	Drifters.push_back(Drifter);
	DrifterActors.Add(Actor);
}

void ACoinRunDirector::UpdateCoins()
{
	const float Time = GetWorld()->GetTimeSeconds();
	for (int32 Index = static_cast<int32>(CoinPositions.size()) - 1; Index >= 0; --Index)
	{
		const coinrun::Vec2 Position = CoinPositions[static_cast<size_t>(Index)];
		if (coinrun::Overlaps(PlayerPosition, ct::kPlayerRadius, Position, ct::kCoinRadius))
		{
			State.OnCoinCollected(nullptr);
			if (AStaticMeshActor* Actor = CoinActors[Index])
			{
				Actor->Destroy();
			}
			CoinActors.RemoveAt(Index);
			CoinPositions.erase(CoinPositions.begin() + Index);
			continue;
		}

		// Gentle bob so coins read as pickups.
		if (AStaticMeshActor* Actor = CoinActors[Index])
		{
			Actor->SetActorLocation(FVector(Position.x, Position.y, ct::kCoinRadius + 8.0f * FMath::Sin(Time * 4.0f + static_cast<float>(Index))));
		}
	}
}

void ACoinRunDirector::UpdateDrifters(float Dt)
{
	const int32 Wave = State.Wave();
	for (size_t Index = 0; Index < Drifters.size(); ++Index)
	{
		FDrifter& Drifter = Drifters[Index];
		const coinrun::Vec2 ToPlayer = (PlayerPosition - Drifter.Position).Normalized();
		Drifter.Direction = coinrun::SteerToward(Drifter.Direction, ToPlayer, ct::DrifterTurnRate(Wave) * Dt);
		Drifter.Position = coinrun::ClampToArena(Drifter.Position + Drifter.Direction * (ct::DrifterSpeed(Wave) * Dt), ct::kArenaHalfExtent, Drifter.Radius);

		if (AStaticMeshActor* Actor = DrifterActors[static_cast<int32>(Index)])
		{
			Actor->SetActorLocation(FVector(Drifter.Position.x, Drifter.Position.y, Drifter.Radius));
		}

		// A dash passes through drifters without a hit.
		if (coinrun::Overlaps(PlayerPosition, ct::kPlayerRadius, Drifter.Position, Drifter.Radius))
		{
			State.OnDrifterHit(DashState.IsActive());
		}
	}
}

void ACoinRunDirector::SyncPlayer()
{
	ACoinRunPawn* Pawn = PlayerPawn.Get();
	if (Pawn == nullptr)
	{
		return;
	}
	Pawn->SetActorLocation(FVector(PlayerPosition.x, PlayerPosition.y, ct::kPlayerRadius));

	// Blink while invulnerable after a hit.
	const bool bBlinkOff = State.IsInvulnerable() && (static_cast<int32>(GetWorld()->GetTimeSeconds() * 10.0f) % 2 == 0);
	Pawn->SetBodyVisible(!bBlinkOff);
}
