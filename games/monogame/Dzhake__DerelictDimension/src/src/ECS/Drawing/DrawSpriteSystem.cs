using DerelictDimension.ECS.PhysicsModule;
using Friflo.Engine.ECS.Systems;
using Monod.ECS.DefaultComponents;
using Monod.Graphics;
using Monod.Graphics.ECS.Sprite;
using Monod.Utils.Extensions;
using System;

namespace DerelictDimension.ECS.Drawing;

public class DrawSpriteSystem : QuerySystem<Sprite2D>
{
    protected override void OnUpdate()
    {
        Renderer.Begin(SpriteSortMode.BackToFront, samplerState: SamplerState.PointWrap);
        Query.ForEachEntity(Draw);
        Renderer.End();
    }

    private void Draw(ref Sprite2D sprite, Entity entity)
    {
        if (sprite.Texture is null || !sprite.Visible) return;

        EntityData data = entity.Data;
        GetDrawArgs(ref sprite, ref entity, ref data, out Vector2 position, out float rotation, out Vector2 scale, out float depth, out Vector2 origin);
        position *= Physics.PixelsInMeter;

        if (data.Has<NineSliceComponent>())
        {
            DrawNineSlice(ref sprite, ref data.Get<NineSliceComponent>(), ref position, rotation, scale, depth, ref origin);
        }
        else
        {
            Renderer.DrawTexture(sprite.Texture!.Base, position, sprite.color, sprite.Texture.Region, rotation, origin, scale, sprite.spriteEffects, depth);
        }
    }

    private void DrawNineSlice(ref Sprite2D sprite, ref NineSliceComponent nineSlice, ref Vector2 position, float rotation, Vector2 scale, float depth, ref Vector2 origin)
    {
        MTexture mTex = sprite.Texture!;
        if (mTex.Base is null)
            return;

        Texture2D texture = mTex.Base;
        Rectangle region = mTex.GetBounds();

        float drawW = nineSlice.DrawSize.X;
        float drawH = nineSlice.DrawSize.Y;

        // if region is smaller than 3 pixels we can't slice it
        if (region.Width < 3 || region.Height < 3 || drawW <= 0f || drawH <= 0f)
            return;

        int tileWidth = region.Width / 3;
        int tileHeight = region.Height / 3;

        int leftSrcX = region.X;
        int midSrcX = leftSrcX + tileWidth;
        int rightSrcX = midSrcX + tileWidth;
        int topSrcY = region.Y;
        int midSrcY = topSrcY + tileHeight;
        int bottomSrcY = midSrcY + tileHeight;

        int middleCols = Math.Max(0, (int)((drawW - (2 * tileWidth)) / tileWidth));
        int middleRows = Math.Max(0, (int)((drawH - (2 * tileHeight)) / tileHeight));

        // world = position + R(rotation) * ((local - origin) * scale), split into:
        // world = (baseX + kx*x + ky*y, baseY + lx*x + ly*y)
        Vector2 localOrigin = new(origin.X * (drawW / region.Width), origin.Y * (drawH / region.Height));

        float cos = MathF.Cos(rotation);
        float sin = MathF.Sin(rotation);
        float oX = localOrigin.X * scale.X;
        float oY = localOrigin.Y * scale.Y;

        float baseX = position.X - cos * oX + sin * oY;
        float baseY = position.Y - sin * oX - cos * oY;
        float kx = cos * scale.X, lx = sin * scale.X;
        float ky = -sin * scale.Y, ly = cos * scale.Y;


        Color color = sprite.color;
        SpriteEffects effects = sprite.spriteEffects;
        bool flipH = (effects & SpriteEffects.FlipHorizontally) != 0;
        bool flipV = (effects & SpriteEffects.FlipVertically) != 0;
        if (flipH) (leftSrcX, rightSrcX) = (rightSrcX, leftSrcX);
        if (flipV) (topSrcY, bottomSrcY) = (bottomSrcY, topSrcY);


        void Tile(int srcX, int srcY, int srcW, int srcH, float dstX, float dstY)
        {
            Renderer.DrawTexture(texture, new Vector2(baseX + kx * dstX + ky * dstY, baseY + lx * dstX + ly * dstY), color, new Rectangle(srcX, srcY, srcW, srcH), rotation, Vector2.Zero, scale, effects, depth);
        }

        void Band(int srcY, int srcH, float dstY)
        {
            Tile(leftSrcX, srcY, tileWidth, srcH, 0f, dstY);

            for (int i = 0; i < middleCols; i++)
                Tile(midSrcX, srcY, tileWidth, srcH, (i + 1) * tileWidth, dstY);

            Tile(rightSrcX, srcY, tileWidth, srcH, (middleCols + 1) * tileWidth, dstY);
        }


        Band(topSrcY, tileHeight, 0f);

        for (int j = 0; j < middleRows; j++)
            Band(midSrcY, tileHeight, tileHeight + j * tileHeight);

        Band(bottomSrcY, tileHeight, drawH - tileHeight);
    }

    private void GetDrawArgs(ref Sprite2D sprite, ref Entity entity, ref EntityData data, out Vector2 position, out float rotation, out Vector2 scale, out float depth, out Vector2 origin)
    {
        position = entity.GetWorldPos(out rotation);
        rotation += sprite.Rotation;
        ref var transform = ref data.Ensure<Transform2D>(CommandBuffer);
        scale = transform.Scale;

        if (data.Has<RenderDepth>())
            depth = data.Get<RenderDepth>().Depth;
        else
            depth = 0;

        origin = new(sprite.Texture!.Base.Width / 2f, sprite.Texture.Base.Height / 2f);
    }
}
