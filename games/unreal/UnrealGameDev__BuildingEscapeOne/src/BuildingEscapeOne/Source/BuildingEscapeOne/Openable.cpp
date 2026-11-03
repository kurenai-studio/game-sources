// Fill out your copyright notice in the Description page of Project Settings.


#include "BuildingEscapeOne.h"
#include "Openable.h"
#include "Switchable.h"

// Sets default values for this component's properties
UOpenable::UOpenable()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UOpenable::BeginPlay()
{
	Super::BeginPlay();
	
	// Check component init values
	if (DependingSwitches.Num() == 0)
	{
		UE_LOG(LogTemp, Warning, TEXT("No depending switch choosen for %s"), *GetOwner()->GetName());
		return;
	}

	// Register EventHandler for every Switchable in Vector
	for (auto& Switch : DependingSwitches)
	{
		USwitchable* Switchable = Switch->FindComponentByClass<USwitchable>();
		if (Switchable)
		{
			Switchable->SwitchEvent.AddDynamic(this, &UOpenable::OnSwichtChange);
			ExpectedSwitchOrder.Add(DependingSwitches.Find(Switch)); // Rember order for later use (index based)
		}
		else
		{
			UE_LOG(LogTemp, Warning, TEXT("No Switchable component found for %s assigned to %s"), *Switch->GetName(), *GetOwner()->GetName());
		}
	}

	
	
	
}


// Called every frame
void UOpenable::TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction )
{
	Super::TickComponent( DeltaTime, TickType, ThisTickFunction );

	// ...
}

void UOpenable::OpenActor()
{
	OnOpen.Broadcast();
	for (auto& Switch : AffectedSwitches)
	{
		USwitchable* Switchable = Switch->FindComponentByClass<USwitchable>();
		if (Switchable)
		{
			Switchable->SetSwitchState(true);
		}
	}
}

void UOpenable::CloseActor()
{
	OnClose.Broadcast();
	for (auto& Switch : AffectedSwitches)
	{
		USwitchable* Switchable = Switch->FindComponentByClass<USwitchable>();
		if (Switchable)
		{
			Switchable->SetSwitchState(false);
		}
	}
}

void UOpenable::OnSwichtChange(AActor * SwitchingActor, bool SwitchState)
{
	TArray<int> FixedSwitchOrder;
	FixedSwitchOrder.Add(1);
	FixedSwitchOrder.Add(3);
	FixedSwitchOrder.Add(4);
	FixedSwitchOrder.Add(5);
	FixedSwitchOrder.Add(7);
	FixedSwitchOrder.Add(10);

	// Update switch array (index based)
	if (SwitchState)
	{
		ActualSwitchOrder.Add(DependingSwitches.Find(SwitchingActor));
	}
	else
	{
		ActualSwitchOrder.Remove(DependingSwitches.Find(SwitchingActor));
	}

	// Check switching condition 
	switch (SwitchingCondition)
	{
	case ESwitchingCondition::SingleOn:
		if (ActualSwitchOrder.Num() >= 1)
		{
			OpenActor();
		}
		else
		{
			CloseActor();
		}
		break;
	case ESwitchingCondition::AllOn:
		if (ActualSwitchOrder.Num() >= DependingSwitches.Num())
		{
			OpenActor();
		}
		else
		{
			CloseActor();
		}
		break;
	case ESwitchingCondition::AllOrderedOn:
		if (ActualSwitchOrder == ExpectedSwitchOrder)
		{
			OpenActor();
		}
		else
		{
			CloseActor();
		}
		break;
	case ESwitchingCondition::Fixed:
		ActualSwitchOrder.Sort();
		FixedSwitchOrder.Sort();
		if (ActualSwitchOrder == FixedSwitchOrder)
		{
			OpenActor();
		}
		else
		{
			CloseActor();
		}
		break;
	default:
		break;
	}
}

