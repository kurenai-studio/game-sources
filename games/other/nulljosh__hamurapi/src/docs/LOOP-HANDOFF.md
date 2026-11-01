# Hamurapi loop handoff (2026-10-05, night)

## What the loop is

Ship Hamurapi to the App Store on iPhone and Mac, then make it playable inside Joshua Tree, then work through the rest of the fleet apps queued for the OS.

## Where things stand

The game was Hamurabi until 2026-10-04. That name is taken on the App Store, so it is Hamurapi everywhere: this repo, the folder, the site (hamurapi.heyitsmejosh.com; the old address still serves) and the store listing. The bundle ID stays `com.nulljosh.hamurabi`.

SUBMITTED on 2026-10-05 at 00:19 PDT. The App Store record is 6819131590. iPhone and Mac 1.0.0 both show Waiting for Review (submission ids cbdc649d and 9debfa8c), with build 202610042011.

The Joshua Tree version is merged (Joshua Tree 2.7.0) and playable in the OS.

## Next, in order

1. Watch the review: `asc status --app 6819131590`. If Apple rejects it, read the reason with `asc web review show --app 6819131590` before changing anything. Do not resubmit into a spam-wave rejection; appeal in Resolution Center.
2. The day Apple approves it: the game is free for its first week. Schedule the $0.99 price for seven days later (command in `MONEY.md`). Anyone who got it free keeps it free.
3. After approval, add the App Store link to the README and the landing page.
4. Joshua Tree: Hamurapi has no sound or difficulty setting in the OS yet.

## Restart prompt

```
/loop until all platforms including Joshua tree are supported. Ship to App Store.
```
