// Fill out your copyright notice in the Description page of Project Settings.


#include "StuckInsideGS.h"

#include "Net/UnrealNetwork.h"

void AStuckInsideGS::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	DOREPLIFETIME(AStuckInsideGS,PowerUsage);
	DOREPLIFETIME(AStuckInsideGS,PowerActive);
	DOREPLIFETIME(AStuckInsideGS,DemonPlayer);
	DOREPLIFETIME(AStuckInsideGS,HumanPlayers);
	DOREPLIFETIME(AStuckInsideGS,currentTime);
	DOREPLIFETIME(AStuckInsideGS,DemonWon);
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
}
