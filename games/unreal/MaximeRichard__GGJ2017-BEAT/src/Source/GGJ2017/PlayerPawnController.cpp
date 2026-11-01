// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "PlayerPawnController.h"

void APlayerPawnController::BindControls() {
	APlayerPawn* Pawn = Cast<APlayerPawn>(GetPawn());
	if (Pawn) {
		Pawn->InputComponent->BindAction("Shoot", IE_Pressed, Pawn, &APlayerPawn::Shoot);
		Pawn->InputComponent->BindAction("Shield", IE_Pressed, Pawn, &APlayerPawn::Shield);
		Pawn->InputComponent->BindAction("Shield", IE_Released, Pawn, &APlayerPawn::ReleaseShield);
	}
	else
		UE_LOG(LogTemp, Warning, TEXT("BindControls() : APlayerPawnController::PlayerPawn* is null!"));
}
