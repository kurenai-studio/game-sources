using DerelictDimension.ECS.Rewinding;
using Friflo.Engine.ECS.Systems;
using Monod.Graphics;
using Monod.Graphics.ECS.Sprite;
using Monod.Graphics.Fonts;
using Monod.InputModule;
using Monod.TimeModule;

namespace DerelictDimension.ECS.Drawing;

public class DrawSystem : SystemGroup
{
    public RenderTarget2D? MainRT;
    public static Vector2 Upscale = Vector2.One;

    public ArchetypeQuery<Sprite2D> SpriteQuery;

    public DrawSystem(string name = "DrawSystem") : base(name) { }


    protected override void OnAddStore(EntityStore store)
    {
        base.OnAddStore(store);
        SpriteQuery = store.Query<Sprite2D>();
    }

    protected override void OnUpdateGroup()
    {
        Point renderSize = Renderer.RenderSize;
        LoadMissingAssets();
        Upscale = new(renderSize.X / TheGame.GameSize.X, renderSize.Y / TheGame.GameSize.Y);

        Renderer.SetRenderTarget(MainRT);
        Renderer.Clear(Color.Green);

        base.OnUpdateGroup();

        DrawFinal();
    }

    private void DrawFinal()
    {
        Renderer.SetRenderTarget(null);
        Vector2 renderOffset = Renderer.RenderOffset;

        Renderer.Begin();
        Renderer.DrawTexture(MainRT!, renderOffset, Color.White);
        Renderer.End();

        Renderer.Begin();
        GlobalFonts.MenuFont.DrawString(Renderer.spriteBatch, $"Time:{Time.TotalTimeSpan}\nCurrent Frame:{Rewind.CurrentFrame}\nEntities:{TheGame.Store.Count}\nMousePos:{Input.MousePos()}", renderOffset, Color.White);
        Renderer.End();
    }

    private void LoadMissingAssets()
    {
        Point renderSize = Renderer.RenderSize;

        if (MainRT is null || MainRT.Bounds.Size != renderSize)
        {
            MainRT?.Dispose();
            MainRT = new(Renderer.device, renderSize.X, renderSize.Y, false, SurfaceFormat.Color, DepthFormat.None, 4, RenderTargetUsage.PreserveContents);
        }
    }
}
