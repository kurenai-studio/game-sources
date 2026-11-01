// Copyright Epic Games, Inc. All Rights Reserved.
// Copyright (c) 2022 Noah Wood

#include "Aghanim_RPGGameMode.h"
#include "Aghanim_RPGCharacter.h"
#include "UObject/ConstructorHelpers.h"

AAghanim_RPGGameMode::AAghanim_RPGGameMode()
{
	
	// set default pawn class to our Blueprinted character
	static ConstructorHelpers::FClassFinder<APawn> PlayerPawnBPClass(TEXT("/Game/ThirdPerson/Blueprints/MainCharacter"));
	if (PlayerPawnBPClass.Class != NULL)
	{
		DefaultPawnClass = PlayerPawnBPClass.Class;
	}
}
