// Fill out your copyright notice in the Description page of Project Settings.


#include "Switch.h"

void ASwitch::Interact(ACharacter* Character)
{
	Super::Interact(Character);
	RightSide = !RightSide;
	if(Switch) Switch->SetRelativeRotation(FRotator(RightSide ? 0 : 180,0,0));
}

ASwitch::ASwitch()
{
	RootComponent = CreateDefaultSubobject<USceneComponent>("Root");
	Switch = CreateDefaultSubobject<UStaticMeshComponent>("Switch");
	Switch->SetupAttachment(RootComponent);
	Switch->SetIsReplicated(true);
	InteractionHB->SetupAttachment(Switch);
}

void ASwitch::BeginPlay()
{
	RightSide = true;
	if(Switch) Switch->SetRelativeRotation(FRotator(RightSide ? 0 : 180,0,0));
	Super::BeginPlay();
}
