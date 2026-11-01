// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "Rotation.h"


// Sets default values for this component's properties
URotation::URotation()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void URotation::BeginPlay()
{
	Super::BeginPlay();
	Actor = GetOwner();
	// ...
	
}


// Called every frame
void URotation::TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction )
{
	Super::TickComponent( DeltaTime, TickType, ThisTickFunction );
	/*GetOwner()->GetActorForwardVector();
	GetOwner()->SetActorRotation(FRotator(0.f, 0.f, 1.f*DeltaTime)*10.f);
	GetOwner()->SetActorLocation(GetOwner()->GetActorForwardVector()*10.f + FVector(0.f,0.f,0.f));*/

	//GetOwner()->FindComponentByClass<UFloatingPawnMovement>()->(FVector(10.f*DeltaTime,0.f,0.f));
	EnemyLevelUpDown(DeltaTime);
	EnemyRotation(DeltaTime);
}

void URotation::SetSpeed(float SpeedValue)
{
	Speed = SpeedValue;
}

void URotation::SetMove(float MoveValue)
{
	Movement = MoveValue;
}

void URotation::SetShoot(bool ShootValue)
{
	Shoot = ShootValue;
}

void URotation::Randomize(int choice) {
	switch (choice)
	{
	case 1:
		SetSpeed(RandomNumber(-100.f, 100.f));
		break;
	case 2:
		
		SetMove(RandomNumber(-50.f, 50.f));
		break;
	case 3:
		//SetSpeed(RandomNumber());
		break;
	default:
		break;
	}
}

float URotation::RandomNumber(float Min, float Max)
{
	return ((float(rand()) / float(RAND_MAX)) * (Max - Min)) + Min;
}

void URotation::EnemyRotation(float DeltaTime)
{
	FVector PivotLocation = FVector(0.f, 0.f, 200.f);
	FRotationMatrix CameraRotation(FRotator(0.f, Speed*DeltaTime, 0.f));

	// Assume the back of the player is -ve x axis
	//const FVector PreTransformedCameraPos(PivotLocation.X+10, 0, 0);
	FVector CameraLocation = PivotLocation + CameraRotation.TransformPosition(Actor->GetActorLocation());
	Actor->SetActorLocation(FVector(CameraLocation.X,CameraLocation.Y, Actor->GetActorLocation().Z));

	// Make Camera look at Target
	Actor->SetActorRotation((PivotLocation - CameraLocation).Rotation());
}

void URotation::EnemyLevelUpDown(float DeltaTime)
{
	FVector EnemyLocation = ClampVector(
				Actor->GetActorLocation() +
				FVector(0.f, 0.f, Movement*DeltaTime),
				FVector(Actor->GetActorLocation().X, Actor->GetActorLocation().Y, 120.f),
				FVector(Actor->GetActorLocation().X, Actor->GetActorLocation().Y, 500.f)
			);
	Actor->SetActorLocation(EnemyLocation);
}

