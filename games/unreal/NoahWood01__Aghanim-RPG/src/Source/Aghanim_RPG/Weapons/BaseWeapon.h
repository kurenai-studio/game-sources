// Copyright (c) 2022 Noah Wood

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Aghanim_RPG/Items/DefaultItem.h"
#include "BaseWeapon.generated.h"


UENUM(BlueprintType)
enum class EWeaponType : uint8
{
	E_Default	UMETA(DisplayName = "DEFAULT"),
	E_Sword		UMETA(DisplayName = "SWORD"),
	E_Dagger	UMETA(DisplayName = "DAGGER"),
	E_Axe		UMETA(DisplayName = "AXE")
};

UCLASS()
class AGHANIM_RPG_API ABaseWeapon : public ADefaultItem
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ABaseWeapon();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Weapon")
		int levelRequirement;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Weapon")
		float damage;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Weapon")
		float baseSpeed;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Weapon")
		EWeaponType weaponType;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

};
