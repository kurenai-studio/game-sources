// Fill out your copyright notice in the Description page of Project Settings.


#include "EnemyHealthBar.h"
#include <Engine/Engine.h>

void UEnemyHealthBar::SetHealth(float newHealth, float maxHealth) {
	float percent = newHealth / maxHealth;
	HealthBar->SetPercent(percent);
}
