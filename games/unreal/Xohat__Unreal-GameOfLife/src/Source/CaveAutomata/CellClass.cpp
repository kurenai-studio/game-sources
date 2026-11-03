// Fill out your copyright notice in the Description page of Project Settings.


#include "CellClass.h"
#include "Components/BoxComponent.h"

// Sets default values
ACellClass::ACellClass()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false;

	//Añadir malla de colisiones para detectar el click
	UBoxComponent* BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("RootComponent"));
	RootComponent = BoxComponent;

	//Crea el spriteComponent
	Sprite = CreateDefaultSubobject<UPaperSpriteComponent>("MySprite");
	Sprite->AttachTo(RootComponent);

	CollisionMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StaticMeshComponent"));
	CollisionMesh->SetupAttachment(RootComponent);

	//Carga el Sprite Asset y lo asigna al Sprite component
	//Ver https://docs.unrealengine.com/latest/INT/Programming/Assets/ReferencingAssets/
	ConstructorHelpers::FObjectFinder<UObject> paperSprite(TEXT("PaperSprite'/Game/Sprites/CellSprite.CellSprite'"));
	Sprite->SetSprite((UPaperSprite*)paperSprite.Object);

	//Estado base = Todo muerto
	lifeState = false;
	
	//Evento de click
	OnClicked.AddUniqueDynamic(this, &ACellClass::OnGetClicked);	

	OnReleased.AddUniqueDynamic(this, &ACellClass::OnMouseRelease);
}

// Called when the game starts or when spawned
void ACellClass::BeginPlay()
{
	Super::BeginPlay();	
}

// Called every frame
void ACellClass::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

void ACellClass::OnGetClicked(AActor* Target, FKey ButtonPressed)
{
	lifeState = !lifeState;

	if (lifeState == true) 
	{
		changedCellCounter += 1;
	}

	else 
	{
		changedCellCounter -= 1;
	}
}

void ACellClass::OnMouseRelease(AActor* Target, FKey ButtonPressed)
{
	if (GEngine)
	{
		GEngine->AddOnScreenDebugMessage(-1, 3.f, FColor::Cyan, TEXT("Changed clicked box status to " + lifeState));
		GEngine->AddOnScreenDebugMessage(-1, 3.f, FColor::Cyan, TEXT("Changed boxes" + changedCellCounter));
	}
}

