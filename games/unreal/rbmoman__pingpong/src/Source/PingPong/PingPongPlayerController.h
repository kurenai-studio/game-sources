#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "PingPongPlayerController.generated.h"

UCLASS()
class PINGPONG_API APingPongPlayerController : public APlayerController
{
	GENERATED_BODY()

public:
	APingPongPlayerController();

	virtual void BeginPlay() override;
	virtual void SetupInputComponent() override;

	float GetMoveAxis() const { return MoveAxis; }

private:
	float MoveAxis;

	void OnMoveAxis(float Value);
	void OnQuit();
};
