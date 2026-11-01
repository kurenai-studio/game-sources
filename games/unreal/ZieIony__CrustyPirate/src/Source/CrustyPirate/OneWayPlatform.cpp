// Fill out your copyright notice in the Description page of Project Settings.


#include "OneWayPlatform.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/Character.h"
#include "Kismet/GameplayStatics.h"
#include "Paper2D/Classes/PaperTileMapComponent.h"

AOneWayPlatform::AOneWayPlatform() {
	PrimaryActorTick.bCanEverTick = true;
}

void AOneWayPlatform::Tick(float dt) {
	Super::Tick(dt);

	updateCollision();
}

void AOneWayPlatform::updateCollision() {
	auto player = UGameplayStatics::GetPlayerCharacter(GetWorld(), 0);
	float playerBottom = player->GetActorLocation().Z - player->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
	float platformTop = GetActorLocation().Z + 30;
	auto response = [&] {
		if (playerBottom > platformTop) {
			return ECollisionResponse::ECR_Block;
		} else {
			return ECollisionResponse::ECR_Ignore;
		}
	}();
	GetRenderComponent()->SetCollisionResponseToChannel(ECollisionChannel::ECC_GameTraceChannel1, response);
}
