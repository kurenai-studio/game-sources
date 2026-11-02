// Fill out your copyright notice in the Description page of Project Settings.


#include "HealthComponent.h"
#include "Kismet/GameplayStatics.h"
#include "ToonTanksGameMode.h"

// Sets default values for this component's properties
UHealthComponent::UHealthComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UHealthComponent::BeginPlay()
{
	Super::BeginPlay();

	Health = MaxHealth;	

	//델리게이트 바인딩
	GetOwner()->OnTakeAnyDamage.AddDynamic(this, &UHealthComponent::DamgeTaken);
	ToonTanksGameMode = Cast<AToonTanksGameMode>(UGameplayStatics::GetGameMode(this));
}



// Called every frame
void UHealthComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

/// <summary>
/// 데미지 콜백 함수
/// </summary>
/// <param name="DamagedActor">데미지를 받을 액터</param>
/// <param name="Damage">데미지 값</param>
/// <param name="DamageType">데미지 타입(화재, 독등) 직접 구현</param>
/// <param name="Instigator">데미지 관리 컨트롤러. 예) 플레이어. nullptr일 수도 있음</param>
/// <param name="DamageCauser">데미지 준 액터</param>
void UHealthComponent::DamgeTaken(AActor* DamagedActor, float Damage, const UDamageType* DamageType, AController* Instigator, AActor* DamageCauser)
{
	if (Damage <= 0.f) return;

	Health -= Damage;
	if (Health <= 0.f && ToonTanksGameMode)
	{
		ToonTanksGameMode->ActorDied(DamagedActor);
	}
}

