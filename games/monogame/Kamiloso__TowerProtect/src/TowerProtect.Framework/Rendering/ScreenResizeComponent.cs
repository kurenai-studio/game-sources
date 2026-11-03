using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using TowerProtect.App.Client.Interfaces;

namespace TowerProtect.Framework.Rendering;

internal class ScreenResizeComponent(Game game, IInputSystem inputSystem) : GameComponent(game)
{
    private GraphicsDeviceManager Graphics => MainGame.Graphics;

    private Point _windowedSize = new(1280, 720);
    private bool _isResizing;

    public override void Initialize()
    {
        Game.Window.AllowUserResizing = true;
        Game.Window.ClientSizeChanged += OnResize;

        Graphics.PreferredBackBufferWidth = _windowedSize.X;
        Graphics.PreferredBackBufferHeight = _windowedSize.Y;
        Graphics.ApplyChanges();

        ToggleFullScreen();
    }

    public override void Update(GameTime gameTime)
    {
        if (inputSystem.IsKeyDown("F11"))
        {
            ToggleFullScreen();
        }

        base.Update(gameTime);
    }

    private void ToggleFullScreen()
    {
        if (!Graphics.IsFullScreen)
        {
            _windowedSize = new Point(
                x: Graphics.PreferredBackBufferWidth,
                y: Graphics.PreferredBackBufferHeight
            );

            Graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;
            Graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;
        }
        else
        {
            Graphics.PreferredBackBufferWidth = _windowedSize.X;
            Graphics.PreferredBackBufferHeight = _windowedSize.Y;
        }

        Graphics.ToggleFullScreen();
    }

    private void OnResize(object? sender, EventArgs e)
    {
        if (_isResizing || Graphics.IsFullScreen)
            return;

        int width = Game.Window.ClientBounds.Width;
        int height = Game.Window.ClientBounds.Height;

        if (width <= 0 || height <= 0)
            return;

        _isResizing = true;

        Graphics.PreferredBackBufferWidth = width;
        Graphics.PreferredBackBufferHeight = height;
        Graphics.ApplyChanges();

        _isResizing = false;
    }
}
