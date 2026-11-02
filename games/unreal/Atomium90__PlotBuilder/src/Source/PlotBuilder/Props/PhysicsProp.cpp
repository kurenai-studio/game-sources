#include "PhysicsProp.h"
#include "Components/StaticMeshComponent.h"
#include "Interaction/HotbarComponent.h"

APhysicsProp::APhysicsProp()
{
	PrimaryActorTick.bCanEverTick = false;

	MeshComponent = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("MeshComponent"));
	SetRootComponent(MeshComponent);

	MeshComponent->SetSimulatePhysics(true);
	MeshComponent->SetCollisionProfileName(FName("BlockAllDynamic"));
}

void APhysicsProp::Interact_Implementation(AActor* InteractingActor)
{
	if (UHotbarComponent* Hotbar = InteractingActor ? InteractingActor->FindComponentByClass<UHotbarComponent>() : nullptr)
	{
		Hotbar->Store(this);
	}
}
