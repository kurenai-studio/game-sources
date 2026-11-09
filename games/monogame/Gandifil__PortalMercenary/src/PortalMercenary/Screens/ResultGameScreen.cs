using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonoGame.Extended.Screens;
using PortalMercenary.Utils;

namespace PortalMercenary.Screens;

public class ResultGameScreen: GameScreen
{
    public static readonly Color BACKGROUND_COLOR = new (32, 40, 78, 255);
    private readonly string[] _text;
    private SpriteFont _font;

    public ResultGameScreen(GameStats gameStats) : base(G.Game)
    {
        _text = gameStats.ToStringArray()
            .Append("Press [ENTER] to try again")
            .Append("Press [ESCAPE] to exit")
            .ToArray();
    }

    public override void LoadContent()
    {
        base.LoadContent();
        
        _font = G.Game.Content.Load<SpriteFont>("fonts/04B_30");
    }
    
    public override void Update(GameTime gameTime)
    {
        if (Keyboard.GetState().IsKeyDown(Keys.Enter))
            ScreenManager.ShowScreen(new TilemapGameScreen("maps/island"));
    }

    public override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(BACKGROUND_COLOR);
            
        var spriteBatch = G.Game.SpriteBatch;
        spriteBatch.Begin();
        for (var i = 0; i < _text.Length; i++)
        {
            var text = _text[i];
            var size = _font.MeasureString(text);
            spriteBatch.DrawString(_font, text, new Vector2((Game.GraphicsDevice.Viewport.Width - size.X) / 2, 50 +i*50 ), Color.White);
        }
        spriteBatch.End();
    }
}