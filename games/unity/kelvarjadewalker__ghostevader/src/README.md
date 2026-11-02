# Ghost Evader

Ghost Evader is a simple game intended for a beginner-level Unity tutorial. It is a vehicle for a viewer's first game using the Unity game engine.

The videos will air as a series. A long-form video that combines all of the episodes into one will be available at the end.

You can find the videos on [YouTube](https://www.youtube.com/playlist?list=PLVu4UqO_SJ8Q).

There is a detailed companion blog post for this series of videos at [Kelvar's Game Dev](https://kelvarsgamedev.com).

## Game Start

The game starts with the player locked in a room. The player must collect coins and stay alive as long as possible.

## Enemies

Enemy ghosts patrol the room when spawned. Initially, they head in the direction of the player. This direction is a snapshot of the player's position at the time the snapshot is taken.

After N seconds, if they have not hit the player, they change direction and take a new snapshot of wherever the player is.

Because these are ghosts, they are not bound to the dungeon walls like the player is. If a ghost goes off screen, it is destroyed to keep the number of enemies down.

## Scoring

As the player picks up coins, points are added to the player's score.

## Player Health

The player starts with 3 lives. Any contact with a ghost kills the player and the round is over. If the player loses all of their lives, the game ends. The player's high score will be saved as a way to teach simple saving using Unity's `PlayerPrefs` class.

## Source Control

The game will be saved to a public GitHub repository. Each video in the series will be saved to a branch. That said, integrating Git itself into the workflow is beyond the scope of the series, to keep it simple.

## Balancing

No balancing is planned for the demo. We will consider adding a mechanic where the level becomes faster after a set number of points. In the end, any expansions will be up to the student.

## Publishing

The game will be published to Itch.io as a web build, so we can walk through the process of publishing a simple game there.

## Future Expansion

The game is intended to be an MVP (minimum viable product). After the series, we will allow viewers to comment and suggest simple additions to the game.

If there is time, we may expand the game on the channel using the most popular suggestions, if any.

## Unity Version
This project was developed using Unity version 6.6. 

## Assets and Credits

All third-party assets in this project are released under [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/), so no attribution is required. They are credited here anyway so you know where to find more. Only CC0 assets are used in this project.

Each third-party asset folder also contains its own README with links to the source and the license. Assets added in later episodes are added to this list in the branch where they first appear.

| Asset | Author | Source | License | Location |
| --- | --- | --- | --- | --- |
| Tiny Dungeon | Kenney | [kenney.nl/assets/tiny-dungeon](https://kenney.nl/assets/tiny-dungeon) | CC0 1.0 | `Assets/Sprites/Kenney/tiny-dungeon` |

## License

The code in this project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Third-party assets are not covered by the MIT License. They keep their own licenses, listed above.

