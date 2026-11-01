// Fill out your copyright notice in the Description page of Project Settings.


#include "SuperSoldier/AI/Controllers/SuperSoldierAIController.h"
#include "BehaviorTree/BlackboardComponent.h"
#include "SuperSoldier/Characters/SuperSoldierCharacter.h"


void ASuperSoldierAIController::BeginPlay() 
{
    Super::BeginPlay();

    if (AIBehavior)
    {
        RunBehaviorTree(AIBehavior);
        APawn* SelfPawn = GetPawn();
        if (SelfPawn && GetBlackboardComponent())
        {
            GetBlackboardComponent()->SetValueAsVector(TEXT("StartLocation"), SelfPawn->GetActorLocation());
            GetBlackboardComponent()->SetValueAsVector(TEXT("PatrolLocation"), SelfPawn->GetActorLocation());
        }
    }
}

bool ASuperSoldierAIController::IsDead() const
{
    ASuperSoldierCharacter* ControlledCharacter = Cast<ASuperSoldierCharacter>(GetPawn());
    
    if (ControlledCharacter)
    {
        return ControlledCharacter->IsDead();
    }
    return true;
}
