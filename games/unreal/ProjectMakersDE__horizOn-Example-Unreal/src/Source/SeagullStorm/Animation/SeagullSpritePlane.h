#pragma once
#include "CoreMinimal.h"
/** Screen up is world -Y: Unreal is left-handed, so a camera looking down cannot show +X right and +Y up. */
constexpr float SeagullScreenUpY = -1.f;
/** Paper2D local X/Z must both lie on arena X/Y. A pitch rotation leaves the sprite vertical. */
inline FQuat SeagullSpritePlane()
{
    return FRotationMatrix::MakeFromXZ(FVector::ForwardVector,FVector::RightVector * SeagullScreenUpY).ToQuat();
}
