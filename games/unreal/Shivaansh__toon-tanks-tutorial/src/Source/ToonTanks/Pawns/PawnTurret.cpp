// Fill out your copyright notice in the Description page of Project Settings.


#include "PawnTurret.h"
#include "Kismet/GameplayStatics.h"
#include "PawnTank.h"

// APawnTurret::APawnTurret()
// {	

// }

void APawnTurret::BeginPlay()
{
	Super::BeginPlay();
    GetWorld()->GetTimerManager().SetTimer(FireRateTimerHandle, this, &APawnTurret::CheckFireCondition, fireRate, true);
	PlayerPawn = Cast<APawnTank>(UGameplayStatics::GetPlayerPawn(this, 0));
}

void APawnTurret::HandleDestruction() 
{
    Super::HandleDestruction();
    Destroy();
}

// Called every frame
void APawnTurret::Tick(float DeltaTime){
	Super::Tick(DeltaTime);

    if(!PlayerPawn || ReturnDistanceToPlayer() > fireRange){
        return;
    }
    UE_LOG(LogTemp, Warning, TEXT("Rotating to player position"));

    RotateTurret(PlayerPawn->GetActorLocation());

}

void APawnTurret::CheckFireCondition() {
    // fire when player alive and in range
    if(!PlayerPawn){
        return;
    }
    if(ReturnDistanceToPlayer() <= fireRange){
        UE_LOG(LogTemp, Warning, TEXT("Firing at player"));
        Fire();
    }
    
}

float APawnTurret::ReturnDistanceToPlayer() {
    if(!PlayerPawn){
        return 0.0f;
    }
    return FVector::Dist(PlayerPawn->GetActorLocation(), GetActorLocation());
}
