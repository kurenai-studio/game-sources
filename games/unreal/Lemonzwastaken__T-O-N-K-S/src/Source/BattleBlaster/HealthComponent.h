#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"

#include "BattleBlasterGameMode.h"

#include "HealthComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnHealthChanged, float, CurrentHealth, float, MaxHealth);

UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class BATTLEBLASTER_API UHealthComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	// Sets default values for this component's properties
	UHealthComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Health")
	float MaxHealth = 100.0f;

	UPROPERTY(VisibleAnywhere)
	float Health;

	ABattleBlasterGameMode* BattleBlasterGameMode;

	UFUNCTION()
	void OnDamageTaken(AActor* DamagedActor, float Damage, const class UDamageType* DamageType, class AController* InstigatedBy, AActor* DamageCauser);

	UPROPERTY(BlueprintAssignable)
	FOnHealthChanged OnHealthChanged;

	UFUNCTION(BlueprintCallable)
	void Heal(float HealAmount);

};