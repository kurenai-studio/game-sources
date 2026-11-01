// Fill out your copyright notice in the Description page of Project Settings.


#include "GrindingPlatform.h"
#include <Components/SplineComponent.h>


AGrindingPlatform::AGrindingPlatform()
{

	if (UStaticMeshComponent* StaticMeshComp = GetStaticMeshComponent())
	{
		GetStaticMeshComponent()->SetCollisionProfileName(FName{ "GrindingPlatform" });
	}





}

void AGrindingPlatform::OnConstruction(const FTransform& Transform)
{

	if (GrindSplines.Contains(nullptr)) return;

	for (UActorComponent* ActorComp : GetComponents())
	{
		USplineComponent* SplineComp = Cast<USplineComponent>(ActorComp);

		if (SplineComp && !GrindSplines.Contains(SplineComp))
		{
			GrindSplines.Add(SplineComp);
		}
	}

	GrindSplines.RemoveAll([this](TObjectPtr<USplineComponent> SplineComp) {

		return SplineComp && SplineComp->GetOwner() != this;

	});

}




#if WITH_EDITOR
void AGrindingPlatform::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangeEvent)
{
	Super::PostEditChangeProperty(PropertyChangeEvent);

	// Handles the case when a new element is added to the GrindSplines array via the editor
	if (PropertyChangeEvent.ChangeType == EPropertyChangeType::ArrayAdd)
	{
		const int32 NullElementIdx = GrindSplines.Find(nullptr);

		if (NullElementIdx != INDEX_NONE)
		{
			TObjectPtr<USplineComponent> NewSplineComp = Cast<USplineComponent>(
				AddComponentByClass(USplineComponent::StaticClass(), false, FTransform{}, false));

			if (!NewSplineComp) return;

			NewSplineComp->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);
			AddInstanceComponent(NewSplineComp);
			NewSplineComp->SetWorldScale3D(FVector{ 1.0 });
			NewSplineComp->SetAbsolute(false, false, true);
			GrindSplines[NullElementIdx] = NewSplineComp;
		}
	}

	// Handles the case when an element in the GrindSplines array is reset via the editor
	{
		TArray<USplineComponent*> SplineCompsInOwnedComps{};
		GetComponents(SplineCompsInOwnedComps);

		for (USplineComponent* SplineComp : SplineCompsInOwnedComps)
		{
			if (!GrindSplines.Contains(SplineComp))
			{
				SplineComp->DestroyComponent();
			}
		}

		GrindSplines.RemoveAll([](TObjectPtr<USplineComponent> SplineComp) {
			return SplineComp == nullptr;
			});
	}
}
#endif // WITH_EDITOR