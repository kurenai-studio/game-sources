using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Diagnostics;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.App.Client.Interfaces;

namespace TowerProtect.Framework.Other;

internal class DiagnosticsComponent(
    Game game,
    IInputSystem inputSystem,
    ICameraView cameraView) : DrawableGameComponent(game)
{
    private SpriteBatch _spriteBatch = null!;
    private Texture2D _backgroundTexture = null!;
    private readonly Process _process = Process.GetCurrentProcess();

    private TimeSpan _lastTime;
    private TimeSpan _lastTotalProcessorTime;

    private int _frameCount;
    private string _cachedText = string.Empty;
    private Vector2 _textSize;
    private bool _enabled;

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        _backgroundTexture = new Texture2D(GraphicsDevice, 1, 1);
        _backgroundTexture.SetData([Color.White]);
    }

    public override void Update(GameTime gameTime)
    {
        if (inputSystem.IsKeyDown("F3"))
        {
            _enabled = !_enabled;

            if (_enabled)
            {
                _lastTime = TimeSpan.Zero;
                _frameCount = 0;
                _cachedText = "Gathering info...";
                _textSize = MainGame.Font.MeasureString(_cachedText);
            }
        }

        if (_enabled)
            RefreshUpdateInfo(gameTime);

        base.Update(gameTime);
    }

    public override void Draw(GameTime gameTime)
    {
        if (_enabled)
        {
            _frameCount++;
            DrawInfo();
        }

        base.Draw(gameTime);
    }

    private void RefreshUpdateInfo(GameTime gameTime)
    {
        if (_lastTime == TimeSpan.Zero)
        {
            _lastTime = gameTime.TotalGameTime;
            _lastTotalProcessorTime = _process.TotalProcessorTime;
            return;
        }

        TimeSpan currentTime = gameTime.TotalGameTime;
        TimeSpan currentTotalProcessorTime = _process.TotalProcessorTime;

        double totalMsPassed = (currentTime - _lastTime).TotalMilliseconds;

        if (totalMsPassed >= 250.0)
        {
            double cpuUsedMs = (currentTotalProcessorTime - _lastTotalProcessorTime).TotalMilliseconds;

            double cpuUsage = (cpuUsedMs / (Environment.ProcessorCount * totalMsPassed)) * 100;
            double fps = _frameCount / (totalMsPassed / 1000.0);
            double frameTime = totalMsPassed / _frameCount;

            _process.Refresh();
            long processMemoryMB = _process.WorkingSet64 / 1048576;
            long managedMemoryMB = GC.GetTotalMemory(false) / 1048576;
            int gc0 = GC.CollectionCount(0);
            int gc1 = GC.CollectionCount(1);
            int gc2 = GC.CollectionCount(2);

            Vec2 cameraPosition = cameraView.Center;

            _cachedText = $"""
                FPS: {fps:0}
                Frame Time: {frameTime:0.00} ms
                Position: {cameraPosition}
                CPU: {cpuUsage:0.0}%
                RAM (Process): {processMemoryMB} MB
                RAM (Managed): {managedMemoryMB} MB
                GC (0/1/2): {gc0} / {gc1} / {gc2}
                """;

            _textSize = MainGame.Font.MeasureString(_cachedText);

            _frameCount = 0;
            _lastTime = currentTime;
            _lastTotalProcessorTime = currentTotalProcessorTime;
        }
    }

    private void DrawInfo()
    {
        if (string.IsNullOrEmpty(_cachedText))
            return;

        _spriteBatch.Begin();

        Rectangle backgroundRect = new(5, 5,
            (int)_textSize.X + 10,
            (int)_textSize.Y + 10);

        _spriteBatch.Draw(_backgroundTexture, backgroundRect, Color.Gray * 0.5f);
        _spriteBatch.DrawString(MainGame.Font, _cachedText, new Vector2(10, 10), Color.White);

        _spriteBatch.End();
    }
}
