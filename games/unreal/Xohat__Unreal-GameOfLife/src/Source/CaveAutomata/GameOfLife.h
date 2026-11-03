// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "CellClass.h"
#include "GameFramework/Actor.h"
#include "GameOfLife.generated.h"

UCLASS()
class CAVEAUTOMATA_API AGameOfLife : public AActor
{
	GENERATED_BODY()
	
public:

	// Prefab de una célula estándar.
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Spawn")
		UClass* genericCellPrefab;

	// Ancho del tablero
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Spawn")
		int width;

	// Alto del tablero
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Spawn")
		int height;

	// Color para una célula void
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Spawn")
		FLinearColor voidColor;

	// Color para una célula live
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Spawn")
		FLinearColor liveColor;

private:
	// Array que representa la caverna
	TArray<int> board;

	//Estado del tablero
	enum BoardState { Idle ,Process, Pause };
	BoardState gridState;

	TArray<ACellClass*> cellList;

	APlayerController* controller;

	int GenerationNumber = 0;

	bool doOnce = false;

public:

	AGameOfLife();

protected:

	virtual void BeginPlay() override;

public:

	virtual void Tick(float DeltaTime) override;

	UFUNCTION(BlueprintCallable)
		void SetState(int code);

private:

	void SetupGrid();

	void UpdateBoard(float DeltaTime);

	void SetGridState();

	void SetDeadGrid();

	void FillGrid();

	void AutomataLocalRule();

	int GetNeighbour(int cell_x, int cell_y);

	void CellSpawn();
};
