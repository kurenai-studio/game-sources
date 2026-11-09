using Monogame.Enchanted.Debug;
using MonoGame.Extended.Tweening;
using PortalMercenary.Screens;

namespace PortalMercenary;

public static class G
{
    public static ContentSchema Content { get; private set; }
    public static Game1 Game { get; private set; }
    public static Tweener Tweener { get; private set; }
    public static TilemapGameScreen Screen { get; private set; }

    public static void GameInit(Game1 game)
    {
        Game = game;
        Tweener = new ();
        Content = new ContentSchema(game.Content);
        
        Log.Info("G.GameInit");
    }

    public static void ScreenInit(TilemapGameScreen tilemapGameScreen)
    {
        Screen = tilemapGameScreen;
        
        Log.Info("G.ScreenInit");
    }
}