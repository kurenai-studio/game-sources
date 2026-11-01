// Copy Right Shijie Xiong


#include "Grab.h"
#include "GameFramework/PlayerController.h"
#include "Engine/World.h"

#define OUT

// Sets default values for this component's properties
UGrab::UGrab()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
}


// Called when the game starts
void UGrab::BeginPlay()
{
	Super::BeginPlay();
	
	SetupInputComponent();
	SetupPhysicsHandleComponent();
}


// Called every frame
void UGrab::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	GetPlayerViewPoint();
	UpdateGrabbedComponentLocation();
}

void UGrab::SetupInputComponent()
{
	InputComponent = GetOwner()->FindComponentByClass<UInputComponent>();

	if (!InputComponent)
	{
		UE_LOG(LogTemp, Error, TEXT("%s is missing Input Component!"), *GetOwner()->GetName());
	}
	else
	{
		InputComponent->BindAction("Grab", IE_Pressed, this, &UGrab::Grab);
		InputComponent->BindAction("Grab", IE_Released, this, &UGrab::Release);
	}
}

void UGrab::SetupPhysicsHandleComponent()
{
	PhysicsHandleComponent = GetOwner()->FindComponentByClass<UPhysicsHandleComponent>();

	if (!PhysicsHandleComponent)
	{
		UE_LOG(LogTemp, Error, TEXT("%s is missing PhysicsHandle Component!"), *GetOwner()->GetName());
	}
}

void UGrab::GetPlayerViewPoint()
{
	GetWorld()->GetFirstPlayerController()->GetPlayerViewPoint(
		OUT PlayerViewPointLocation,
		OUT PlayerViewPointRotation
	);
}

FVector UGrab::GetPlayerReachPoint(float Ratio)
{
	return PlayerViewPointLocation + PlayerViewPointRotation.Vector() * ReachDistance * Ratio;
}

void UGrab::Grab()
{
	FHitResult HitResult;
	GetWorld()->LineTraceSingleByObjectType(
		OUT HitResult,
		PlayerViewPointLocation,
		GetPlayerReachPoint(NormalRatio),
		FCollisionObjectQueryParams(ECollisionChannel::ECC_PhysicsBody),
		FCollisionQueryParams(FName(TEXT("")), false, GetOwner())
	);

	if (HitResult.GetActor())
	{
		HitDistanceRatio = HitResult.Distance / ReachDistance;
		if (PhysicsHandleComponent)
		{
			PhysicsHandleComponent->GrabComponentAtLocation(
				HitResult.GetComponent(),
				NAME_None,
				HitResult.Location
			);
		}
	}
}

void UGrab::Release()
{
	if (PhysicsHandleComponent && PhysicsHandleComponent->GrabbedComponent)
	{
		PhysicsHandleComponent->ReleaseComponent();
	}
}

void UGrab::UpdateGrabbedComponentLocation()
{
	if (PhysicsHandleComponent && PhysicsHandleComponent->GrabbedComponent)
	{
		PhysicsHandleComponent->SetTargetLocation(GetPlayerReachPoint(HitDistanceRatio));
	}
}
