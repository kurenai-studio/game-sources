#pragma once

#include "CoreMinimal.h"
#include "Components/SceneComponent.h"
#include "Animation/SeagullCutoutPose.h"
#include "SeagullCutoutRigComponent.generated.h"

class UPaperSpriteComponent;

// Actor-owned visual parts. Gameplay collision and movement stay on the actor.
UCLASS()
class USeagullCutoutRigComponent : public USceneComponent
{
	GENERATED_BODY()
public:
	USeagullCutoutRigComponent();
	bool Initialize(SeagullCutout::Character Kind, float CanvasWorldWidth);
	void UpdatePose(float DeltaTime, bool Moving, float Facing, const FLinearColor& Tint);
	void PlayAttack() { if (!bFrozen) PoseClock.Attack(); }
	void PlayHurt() { if (!bFrozen) PoseClock.Hurt(); }
	void Freeze() { bFrozen = true; }
	bool IsReady() const { return Parts.Num() > 0; }
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
private:
	UPROPERTY()
	TArray<UPaperSpriteComponent*> Parts;
	UPROPERTY()
	UPaperSpriteComponent* Shadow = nullptr;
	SeagullCutout::Character Character = SeagullCutout::Character::Gull;
	SeagullCutout::Clock PoseClock;
	float UnitsPerPixel = 1.f;
	bool bFrozen = false;
};
