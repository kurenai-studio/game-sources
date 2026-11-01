#include "Pickups/SeagullPickup_Coin.h"
#include "Core/SeagullTypes.h"
#include "PaperFlipbook.h"
#include "PaperFlipbookComponent.h"

ASeagullPickup_Coin::ASeagullPickup_Coin()
{
	PickupType = ESeagullPickupType::Coin;

	// Flipbook asset is editor-created (see EDITOR_SETUP.md); null-guarded.
	// Cached: coins spawn repeatedly during a run.
	if (UPaperFlipbook* Flipbook = SeagullAssets::LoadFlipbookCached(TEXT("/Game/Flipbooks/FB_Coin")))
	{
		if (SpriteComponent)
		{
			SpriteComponent->SetFlipbook(Flipbook);
		}
	}
}

void ASeagullPickup_Coin::OnPickedUp(ASeagullPlayerPawn* Player)
{
	// Coins are visual only -- actual coins derived from score at game over
	Super::OnPickedUp(Player);
}
