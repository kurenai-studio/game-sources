using Microsoft.Xna.Framework;
using Super = Microsoft.Xna.Framework.DrawableGameComponent;

namespace TowerProtect.Framework.Patches;

internal abstract class DrawableGameComponent(Game game) : Super(game)
{
    public MainGame MainGame => (MainGame)Game;
}
