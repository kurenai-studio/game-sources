#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SeagullMapGenerator.generated.h"

UCLASS()
class ASeagullMapGenerator : public AActor
{
	GENERATED_BODY()

public:
	ASeagullMapGenerator();

	virtual void BeginPlay() override;

	void GenerateArena();

private:
	void SpawnGroundTile(const FVector& Position, const FLinearColor& Color, const FVector2D& Size);
};
