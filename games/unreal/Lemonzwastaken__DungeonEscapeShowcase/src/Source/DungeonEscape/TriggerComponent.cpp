// Fill out your copyright notice in the Description page of Project Settings.


#include "TriggerComponent.h"

UTriggerComponent::UTriggerComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

}

void UTriggerComponent::BeginPlay()
{
	Super::BeginPlay();


	//Sets Mover if MoverActor exists
	if (MoverActor)
	{
		Mover = MoverActor->FindComponentByClass<UMover>();
	}

	if (IsPressurePlate)
	{
		OnComponentBeginOverlap.AddDynamic(this, &UTriggerComponent::OnOverlapBegin);
		OnComponentEndOverlap.AddDynamic(this, &UTriggerComponent::OnOverlapEnd);

		StartLocation = GetOwner()->GetActorLocation();
		EndLocation = StartLocation + MoveOffset;


	}

}

void UTriggerComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	//Moving the pressure plate
	FVector CurrentLocation = GetOwner()->GetActorLocation();
	ReachedTarget = CurrentLocation.Equals(FinalLocation);
	float MoveTime = 3.0f;

	if (IsTriggered && (!ReachedTarget))
	{
		float Speed = MoveOffset.Length() / MoveTime;
		FVector NewLocation = FMath::VInterpConstantTo(CurrentLocation, EndLocation, DeltaTime, Speed);

		GetOwner()->SetActorLocation(NewLocation);
	}
	else
	{
		float Speed = MoveOffset.Length() / MoveTime;
		FVector NewLocation = FMath::VInterpConstantTo(CurrentLocation, StartLocation, DeltaTime, Speed);

		GetOwner()->SetActorLocation(NewLocation);
	}


}

void UTriggerComponent::Trigger(bool NewTrigggerValue)
{
	IsTriggered = NewTrigggerValue;

	if (Mover)
	{
		Mover->SetShouldMove(IsTriggered);
	}

}

void UTriggerComponent::OnOverlapBegin(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult)
{
	if (OtherActor && OtherActor->ActorHasTag("PressurePlateActivator"))
	{
		//Set Activator Count
		ActivatorCount ++;


		if (!IsTriggered)
		{
			FinalLocation = EndLocation;
			Trigger(true);
		}
	}
}

void UTriggerComponent::OnOverlapEnd(UPrimitiveComponent* OverlappedComp, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex)
{
	if (OtherActor && OtherActor->ActorHasTag("PressurePlateActivator"))
	{
		//Set Activator Count
		ActivatorCount --;
		if (IsTriggered && (ActivatorCount <= 0))
		{
			FinalLocation = StartLocation;
			Trigger(false);
		}
	}
}

