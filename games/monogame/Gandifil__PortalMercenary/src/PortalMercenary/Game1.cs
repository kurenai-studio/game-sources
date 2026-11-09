using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Monogame.Enchanted;
using MonoGame.Extended;
using MonoGame.Extended.ViewportAdapters;
using PortalMercenary.Screens;

namespace PortalMercenary;

public class Game1 : BaseGame
{
    public const int TILE_WIDTH = 64;
    public const int TILE_HEIGHT = 64;
    
    public readonly OrthographicCamera Camera;

    public Game1(): base("Викинги: Кровь на Траве", 800, 480, false) 
    { 
        var viewportAdapter = new BoxingViewportAdapter(Window, GraphicsDevice, 800, 480);
        Camera = new OrthographicCamera(viewportAdapter);
    }

    protected override void Initialize()
    {
        G.GameInit(this);
        base.Initialize();
    }

    protected override void BeginRun()
    {
        base.BeginRun();
        ScreenManager.ShowScreen(new TilemapGameScreen("maps/island"));
    }

    protected override void Update(GameTime gameTime)
    {
        var keys = Keyboard.GetState();
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
            keys.IsKeyDown(Keys.Escape))
            Exit();

        G.Tweener.Update(gameTime.GetElapsedSeconds());
        base.Update(gameTime);
    }
}