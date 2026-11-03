// Fill out your copyright notice in the Description page of Project Settings.


#include "PawnTurret.h"
#include "Kismet/GameplayStatics.h" // To implement timer functionalities
#include "PawnTank.h"

// Called when the game starts or when spawned
void APawnTurret::BeginPlay()
{
    Super::BeginPlay();

    GetWorld()->GetTimerManager().SetTimer(FireRateTimerHandle, this, &APawnTurret::CheckFireCondition, FireRate, true);
    // GetWorldTimerManager() Same thing as above

    // Cast - Cross class communication - allows us to convert a provided type to another using the built-in reflection system in UE
    // Here we are passing a generic Pawn class, which is the base class of all controllable classes and then we'll be converting it
    // to check whether it is not only APawn but it is a type of APawnTank class
    // This allows us to access any exposed Tank-specific functionalities since we'll have a reference to not just APawn but the specific Tank version.
    PlayerPawn = Cast<APawnTank>(UGameplayStatics::GetPlayerPawn(this, 0));
}

void APawnTurret::HandleDestruction() 
{
    // Call base pawn class HandleDestruction to play effects
    Super::HandleDestruction();

    Destroy();
}

// Called every frame
void APawnTurret::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    if(!PlayerPawn || ReturnDistanceToPlayer() > FireRange)
    {
        return;
    }

    RotateTurret(PlayerPawn->GetActorLocation());
}

void APawnTurret::CheckFireCondition()
{
    // If Player == null || is Dead then BAIL!!
    if (!PlayerPawn || !PlayerPawn->GetIsPlayerAlive())
    {
        return;
    }
    

    // If Player IS in range then FIRE!!
    if (ReturnDistanceToPlayer() <= FireRange)
    {
        Fire();
    }
    
    // UE_LOG(LogTemp, Warning, TEXT("Fire Condition Checked"));
}

float APawnTurret::ReturnDistanceToPlayer()
{
        if (!PlayerPawn)
    {
        return 0.0f;
    }

    // Remember to include PawnTank.h if you want to use its functionalities
    return FVector::Dist(PlayerPawn->GetActorLocation(), GetActorLocation());
}
