using Microsoft.Xna.Framework;
using Super = Microsoft.Xna.Framework.GameComponent;

namespace TowerProtect.Framework.Patches;

internal abstract class GameComponent(Game game) : Super(game)
{
    public MainGame MainGame => (MainGame)Game;
}
