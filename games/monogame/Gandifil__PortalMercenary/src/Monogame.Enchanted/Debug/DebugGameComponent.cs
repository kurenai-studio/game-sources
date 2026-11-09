using ImGuiNET;
using ImGuiNET.SampleProgram.XNA;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Monogame.Enchanted.Debug.Inspection;
using MonoGame.Extended;
using Vector2 = System.Numerics.Vector2;

namespace Monogame.Enchanted.Debug;

internal class DebugGameComponent: SimpleDrawableGameComponent
{
    private readonly FrameCounter _frameCounter;
    private readonly ImGuiRenderer _imGuiRenderer;

    public DebugGameComponent(Game game)
    {
        _frameCounter = new FrameCounter();
        _imGuiRenderer = new ImGuiRenderer(game);
        _imGuiRenderer.RebuildFontAtlas();
        DrawOrder = 100;
        Visible = false;
    }

    public override void Update(GameTime gameTime)
    {
        if (Keyboard.GetState().IsKeyDown(Keys.OemTilde))
            Visible = !Visible;
        _frameCounter.Update(gameTime.GetElapsedSeconds());
    }

    public override void Draw(GameTime gameTime)
    {
        _imGuiRenderer.BeforeLayout(gameTime);
        DrawPerformanceWindow();

        Inspector.Draw();
        _imGuiRenderer.AfterLayout();
    }

    private void DrawPerformanceWindow()
    {
        ImGui.Begin("Performance");
        var currentSize = ImGui.GetWindowSize();
        ImGui.SetWindowSize("Performance", new System.Numerics.Vector2(MathHelper.Max(100, currentSize.X), MathHelper.Max(100, currentSize.Y)));
        ImGui.PlotHistogram("Frame Time", ref _frameCounter.DeltaTimes.Data[0], _frameCounter.DeltaTimes.Data.Length, 0,
            null, 0f, 0.3f, new Vector2(200, 50));
        ImGui.Text($"FPS: {1f / _frameCounter.DeltaTimes[-1]}");
        ImGui.End();
    }
}