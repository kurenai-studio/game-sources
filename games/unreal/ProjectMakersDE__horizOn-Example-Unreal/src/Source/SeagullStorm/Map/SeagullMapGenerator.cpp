#include "Map/SeagullMapGenerator.h"
#include "Animation/SeagullSpritePlane.h"
#include "Core/SeagullTypes.h"
#include "PaperSprite.h"
#include "PaperSpriteComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "SeagullStorm.h"

ASeagullMapGenerator::ASeagullMapGenerator()
{
    PrimaryActorTick.bCanEverTick = false;
    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
}

void ASeagullMapGenerator::BeginPlay()
{
    Super::BeginPlay();
    GenerateArena();
}

void ASeagullMapGenerator::GenerateArena()
{
    // The camera follows the player at the shore; keep water behind the artwork.
    SpawnGroundTile(FVector(0.f, 0.f, -6.f), SeagullColors::Water,
        FVector2D(SeagullConstants::ArenaWidth + 1440.f, SeagullConstants::ArenaHeight + 1440.f));
    UPaperSprite* ArenaSprite = LoadObject<UPaperSprite>(nullptr, TEXT("/Game/Sprites/SP_Arena"));
    if (ArenaSprite)
    {
        UPaperSpriteComponent* Background = NewObject<UPaperSpriteComponent>(this, TEXT("ArenaArtwork"));
        Background->SetupAttachment(RootComponent);
        Background->SetSprite(ArenaSprite);
        Background->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Background->SetRelativeRotation(SeagullSpritePlane());
        Background->SetRelativeLocation(FVector(0.f, 0.f, -5.f));
        const FVector Extents = Background->CalcBounds(FTransform::Identity).BoxExtent;
        Background->SetRelativeScale3D(FVector(
            SeagullConstants::ArenaWidth / FMath::Max(1.f, Extents.X * 2.f), 1.f,
            SeagullConstants::ArenaHeight / FMath::Max(1.f, Extents.Z * 2.f)));
        Background->RegisterComponent();
        return;
    }
    // Two large planes replace thousands of individual ground components.
    SpawnGroundTile(FVector(0.f, 0.f, -5.f), SeagullColors::Sand,
        FVector2D(SeagullConstants::ArenaWidth, SeagullConstants::ArenaHeight));
    UE_LOG(LogSeagullStorm, Warning, TEXT("Arena artwork unavailable. Run Scripts/setup_editor_assets.py in Unreal Editor."));
}

void ASeagullMapGenerator::SpawnGroundTile(const FVector& Position, const FLinearColor& Color, const FVector2D& Size)
{
    UStaticMeshComponent* Tile = NewObject<UStaticMeshComponent>(this);
    Tile->SetupAttachment(RootComponent);
    Tile->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Tile->SetStaticMesh(LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Plane.Plane")));
    Tile->SetRelativeLocation(Position);
    Tile->SetRelativeScale3D(FVector(Size.X / 100.f, Size.Y / 100.f, 1.f));
    UMaterialInterface* Base = LoadObject<UMaterialInterface>(nullptr, TEXT("/Game/Materials/M_ArenaColor"));
    if (Base)
    {
        UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(Base, this);
        Material->SetVectorParameterValue(TEXT("Color"), Color);
        Tile->SetMaterial(0, Material);
    }
    Tile->RegisterComponent();
}
