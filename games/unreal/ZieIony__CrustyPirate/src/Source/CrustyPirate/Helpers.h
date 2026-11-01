#pragma once

#include "CoreMinimal.h"

template <class T>
void DestroyAllActorsOfClass(UWorld* world) {
	TArray<AActor*> actors;
	UGameplayStatics::GetAllActorsOfClass(world, T::StaticClass(), actors);
	for (auto actor : actors) {
		actor->Destroy();
	}
}
