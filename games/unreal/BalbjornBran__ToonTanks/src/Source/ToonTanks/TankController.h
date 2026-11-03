// Created by Balbjorn Bran.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "TankController.generated.h"

class UInputMappingContext;
class ATank;

/**
*  Vehicle Player Controller class
*  Handles input mapping
*/
UCLASS(abstract)
class TOONTANKS_API ATankController : public APlayerController
{
	GENERATED_BODY()

protected:

	/** Input Mapping Context to be used for player input */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = Input)
	UInputMappingContext* InputMappingContext;

	/** Pointer to the controlled vehicle pawn */
	TObjectPtr<ATank> VehiclePawn;
	
	virtual void BeginPlay() override;
	virtual void SetupInputComponent() override;
	virtual void OnPossess(APawn* InPawn) override;

public:

	virtual void Tick(float Delta) override;
	void SetPlayerEnabledState(bool bEnabled);
	
	
};
