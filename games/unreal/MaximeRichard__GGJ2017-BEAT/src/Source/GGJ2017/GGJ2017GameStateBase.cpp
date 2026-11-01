// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "GGJ2017GameStateBase.h"

AGGJ2017GameStateBase::AGGJ2017GameStateBase() {

	GlobalEventHandler = CreateDefaultSubobject<UGlobalEventManager>(FName("Event Handler"));
}

