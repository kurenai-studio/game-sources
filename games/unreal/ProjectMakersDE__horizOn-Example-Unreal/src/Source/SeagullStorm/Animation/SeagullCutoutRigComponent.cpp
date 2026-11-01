#include "Animation/SeagullCutoutRigComponent.h"
#include "Animation/SeagullSpritePlane.h"
#include "PaperSprite.h"
#include "PaperSpriteComponent.h"
#include "GameFramework/Actor.h"
#include "Misc/PackageName.h"

namespace
{
UPaperSprite* LoadPartCached(const FString& Path)
{
	static TMap<FString, TWeakObjectPtr<UPaperSprite>> Cache;
	static TSet<FString> Missing;
	TWeakObjectPtr<UPaperSprite>& Sprite = Cache.FindOrAdd(Path);
	if (!Sprite.IsValid())
	{
		if (!Missing.Contains(Path))
		{
			Sprite = LoadObject<UPaperSprite>(nullptr, *Path);
			if (!Sprite.IsValid()) Missing.Add(Path);
		}
		else
		{
			const FString ObjectPath = FString::Printf(TEXT("%s.%s"), *Path, *FPackageName::GetShortName(Path));
			Sprite = FindObject<UPaperSprite>(nullptr, *ObjectPath);
			if (Sprite.IsValid()) Missing.Remove(Path);
		}
	}
	return Sprite.Get();
}

}

USeagullCutoutRigComponent::USeagullCutoutRigComponent()
{
	// Only the gameplay actor advances the clock. World pause stops its tick.
	PrimaryComponentTick.bCanEverTick = false;
}

bool USeagullCutoutRigComponent::Initialize(SeagullCutout::Character Kind, float CanvasWorldWidth)
{
	if (IsReady()) return true;
	Character = Kind;
	PoseClock = SeagullCutout::Clock();
	bFrozen = false;
	const auto& Definition = SeagullCutout::GetDefinition(Kind);
	UnitsPerPixel = CanvasWorldWidth / Definition.Canvas;
	const TCHAR* Family = Kind == SeagullCutout::Character::Gull ? TEXT("gull") : TEXT("crab");
	TArray<UPaperSprite*> Sprites;
	// Resolve the entire rig before hiding its old full-image fallback.
	for (int32 I = 0; I < Definition.Count; ++I)
	{
		const FString Path = FString::Printf(TEXT("/Game/Sprites/Cutout/SP_Cutout_%s_%s"), Family, UTF8_TO_TCHAR(Definition.Parts[I].Name));
		UPaperSprite* Sprite = LoadPartCached(Path);
		if (!Sprite) return false;
		Sprites.Add(Sprite);
	}
	UPaperSprite* ShadowSprite = LoadPartCached(TEXT("/Game/Sprites/Cutout/SP_Cutout_shadow"));
	if (!ShadowSprite) return false;
	for (int32 I = 0; I < Sprites.Num(); ++I)
	{
		UPaperSpriteComponent* Part = NewObject<UPaperSpriteComponent>(GetOwner());
		GetOwner()->AddInstanceComponent(Part);
		Part->SetupAttachment(this);
		Part->SetSprite(Sprites[I]);
		Part->SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Part->SetGenerateOverlapEvents(false);
		Part->SetCastShadow(false);
		Part->RegisterComponent();
		Parts.Add(Part);
	}
	Shadow = NewObject<UPaperSpriteComponent>(GetOwner());
	GetOwner()->AddInstanceComponent(Shadow);
	Shadow->SetupAttachment(this);
	Shadow->SetSprite(ShadowSprite);
	Shadow->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Shadow->SetGenerateOverlapEvents(false);
	Shadow->SetCastShadow(false);
	Shadow->SetRelativeRotation(SeagullSpritePlane());
	Shadow->SetRelativeLocation(FVector((Definition.FeetX - Definition.ActorX) * UnitsPerPixel, (Definition.ActorY - Definition.FeetY - 4.f) * UnitsPerPixel * SeagullScreenUpY, 1.f));
	// Imported at a unit width, then sized beneath the existing canvas width.
	Shadow->SetRelativeScale3D(FVector(CanvasWorldWidth * .54f, 1.f, CanvasWorldWidth * .30f));
	Shadow->RegisterComponent();
	UpdatePose(0.f, false, 1.f, FLinearColor::White);
	return true;
}

void USeagullCutoutRigComponent::UpdatePose(float DeltaTime, bool Moving, float Facing, const FLinearColor& Tint)
{
	if (!IsReady() || bFrozen) return;
	PoseClock.Advance(DeltaTime);
	const auto& Definition = SeagullCutout::GetDefinition(Character);
	const auto Pose = SeagullCutout::Sample(Character, PoseClock.Current(Moving), PoseClock.Phase(), Moving, PoseClock.TimeSeconds());
	// Mirror the whole parent so pivots, translations and limb angles agree.
	SetRelativeScale3D(FVector((Facing < 0.f ? -1.f : 1.f) * Definition.BaseFacing, 1.f, 1.f));
	for (int32 I = 0; I < Parts.Num(); ++I)
	{
		const auto Position = SeagullCutout::Project(Definition, Definition.Parts[I].X, Definition.Parts[I].Y, Pose.Parts[I], Pose.Lean, Pose.Hop, 1.f);
		Parts[I]->SetRelativeLocation(FVector(Position.X * UnitsPerPixel, Position.Y * UnitsPerPixel * SeagullScreenUpY, 2.f + I * .05f));
		const float Yaw = SeagullCutout::WorldYaw(Pose.Parts[I].Angle + Pose.Lean);
		Parts[I]->SetRelativeRotation(FQuat(FVector::UpVector, Yaw) * SeagullSpritePlane());
		Parts[I]->SetSpriteColor(Tint);
	}
}

void USeagullCutoutRigComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	for (UPaperSpriteComponent* Part : Parts) if (IsValid(Part)) Part->DestroyComponent();
	Parts.Empty();
	if (IsValid(Shadow)) Shadow->DestroyComponent();
	Shadow = nullptr;
	Super::EndPlay(EndPlayReason);
}
