// Fill out your copyright notice in the Description page of Project Settings.


#include "GameOfLife.h"

// Sets default values
AGameOfLife::AGameOfLife()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
}

// Called when the game starts or when spawned
void AGameOfLife::BeginPlay()
{
	Super::BeginPlay();

	//Establece los parámetros iniciales de la caverna y spawnea los prefabs
	SetupGrid();
	gridState = BoardState::Idle;
}

// Called every frame
void AGameOfLife::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	//Se pinta el tablero
	SetGridState();
	UpdateBoard(DeltaTime);
}

void AGameOfLife::SetupGrid() //SetupGrid
{
	//Dimensiona el array del tablero con el número de células
	board.AddDefaulted(width * height);

	//Añade células estándar al array de células
	FillGrid();

	SetDeadGrid();
}

void AGameOfLife::SetGridState() //SetGridState
{
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			//Acceso a los componentes sprite del actor
			TArray<UActorComponent*> sprites = cellList[(y * width) + x]->GetComponentsByClass(UPaperSpriteComponent::StaticClass());

			if (sprites.Num() > 0)
			{
				if (board[(y * width) + x] == 1)
				{
					//Cambia el color del sprite
					((UPaperSpriteComponent*)sprites[0])->SetSpriteColor(liveColor);
				}
				else
				{
					//Cambia el color del sprite
					((UPaperSpriteComponent*)sprites[0])->SetSpriteColor(voidColor);
				}
			}
		}
	}
}

void AGameOfLife::UpdateBoard(float DeltaTime) 
{
	if (gridState == BoardState::Process) 
	{
		AutomataLocalRule();
		GenerationNumber += 1;

		if (GenerationNumber >= 25 && !doOnce) 
		{
			if (GEngine)
			{
				GEngine->AddOnScreenDebugMessage(-1, 3.f, FColor::Cyan, TEXT("Generation " + GenerationNumber));
				doOnce = true;
			}
		}
	}

	else if (gridState == BoardState::Idle) 
	{
		CellSpawn();
	}
}

//Añade células estándar al array de células a partir del spawn de prefabs
void AGameOfLife::FillGrid()
{
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			FVector* location = new FVector((-width * 100) / 2 + (x * 100) + 50, 0, (-height * 100) / 2 + (y * 100) + 50);
			FRotator* rotation = new FRotator(0, 0, 0);
			FActorSpawnParameters params;

			//Spawn actor
			ACellClass* cell = (ACellClass*)GetWorld()->SpawnActor(genericCellPrefab, location, rotation, params);
			//Accede a la variable pública info de la clase ACellClass

			cell->info = FVector2D(x, y);
			cellList.Add(cell);		
		}
	}
}

void AGameOfLife::SetDeadGrid()
{
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			//Acceso a los componentes sprite del actor
			TArray<UActorComponent*> sprites = cellList[(y * width) + x]->GetComponentsByClass(UPaperSpriteComponent::StaticClass());

			if (sprites.Num() > 0)
			{
				((UPaperSpriteComponent*)sprites[0])->SetSpriteColor(voidColor);
			}
		}
	}
}

void AGameOfLife::AutomataLocalRule()
{
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			//Obtiene la población de células vecinas
			int neighbourCellTiles = GetNeighbour(x, y);

			if (board[(y * width) + x] == 1 && (neighbourCellTiles < 2 || neighbourCellTiles > 3))
			{
				board[(y * width) + x] = 0;
			}

			else if (board[(y * width) + x] == 0 && neighbourCellTiles == 3) 
			{
				board[(y * width) + x] = 1;
			}
		}
	}
}

int AGameOfLife::GetNeighbour(int cell_x, int cell_y)
{
	int cellCount = 0;

	//Recorre un grid de +-1 en sentido horizontal
	for (int neighbourX = cell_x - 1; neighbourX <= cell_x + 1; neighbourX++)
	{
		//Recorre un grid de +-1 en sentido vertical
		for (int neighbourY = cell_y - 1; neighbourY <= cell_y + 1; neighbourY++)
		{
			//Comprueba que no se salga de los límites del sujeto de prueba
			if (neighbourX >= 0 && neighbourX < width && neighbourY >= 0 && neighbourY < height)
			{
				if (neighbourX != cell_x || neighbourY != cell_y)
				{
					cellCount += board[(neighbourY * width) + neighbourX];
				}
			}
		}
	}

	return cellCount;
}

void AGameOfLife::SetState(int SwitchCase) 
{
	CellSpawn();
	gridState = BoardState::Process;
}

void AGameOfLife::CellSpawn() 
{
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			ACellClass* cell = cellList[((y * width) + x)];

			if (cell->lifeState) 
			{
				board[(y * width) + x] = 1;
			}

			else 
			{
				board[(y * width) + x] = 0;
			}
		}
	}
}

