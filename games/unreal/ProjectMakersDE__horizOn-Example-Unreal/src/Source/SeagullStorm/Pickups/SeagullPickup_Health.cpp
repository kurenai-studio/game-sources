#include "Pickups/SeagullPickup_Health.h"
#include "Player/SeagullPlayerPawn.h"
#include "Player/SeagullHealthComponent.h"
#include "Core/SeagullTypes.h"
#include "PaperFlipbookComponent.h"

ASeagullPickup_Health::ASeagullPickup_Health()
{
    PickupType = ESeagullPickupType::Health;
    if (UPaperFlipbook* Flipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Health")))
        SpriteComponent->SetFlipbook(Flipbook);
}

void ASeagullPickup_Health::OnPickedUp(ASeagullPlayerPawn* Player)
{
    if (Player && Player->HealthComponent) Player->HealthComponent->Heal(30);
    Super::OnPickedUp(Player);
}
