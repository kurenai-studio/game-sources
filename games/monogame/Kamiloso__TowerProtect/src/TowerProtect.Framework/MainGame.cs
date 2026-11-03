using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using TowerProtect.Domain;

namespace TowerProtect.Framework;

internal class MainGame : Game
{
    public GraphicsDeviceManager Graphics { get; }
    public Viewport Viewport => GraphicsDevice.Viewport;
    public SpriteFont Font { get; private set; } = null!;

    public MainGame()
    {
        Graphics = new GraphicsDeviceManager(this)
        {
            IsFullScreen = false,
            HardwareModeSwitch = false,
            SynchronizeWithVerticalRetrace = true,
            GraphicsProfile = GraphicsProfile.HiDef,
            PreferMultiSampling = true,
        };

        Content.RootDirectory = "Content";
        IsMouseVisible = true;
        IsFixedTimeStep = true;
    }

    protected override void LoadContent()
    {
        Font = Content.Load<SpriteFont>(Assets.PTSansBold);

        base.LoadContent();
    }
}
