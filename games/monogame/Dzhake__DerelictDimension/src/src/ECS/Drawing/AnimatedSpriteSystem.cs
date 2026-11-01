using Friflo.Engine.ECS.Systems;
using Monod.Graphics.ECS.Sprite;
using Monod.TimeModule;
using Monod.Utils.Extensions;

namespace DerelictDimension.ECS.Drawing;

public class AnimatedSpriteSystem : QuerySystem<AnimatedSpriteComponent>
{
    protected override void OnUpdate()
    {
        Query.ForEachEntity(UpdateEntity);
    }

    private void UpdateEntity(ref AnimatedSpriteComponent animatedSprite, Entity entity)
    {
        var data = entity.Data;

        animatedSprite.FrameRemainder += Time.DeltaTime;

        bool frameChanged = animatedSprite.FrameRemainder > animatedSprite.EffectiveTimeBetweenFrames;
        if (frameChanged)
        {
            animatedSprite.FrameNumber = (animatedSprite.FrameNumber + (int)(animatedSprite.FrameRemainder / animatedSprite.EffectiveTimeBetweenFrames)) % animatedSprite.Frames.Length;
            animatedSprite.FrameRemainder %= animatedSprite.EffectiveTimeBetweenFrames;
        }

        string texturePath = animatedSprite.BaseTexturePath + animatedSprite.Frames[animatedSprite.FrameNumber];

        ref var sprite2D = ref data.Ensure<Sprite2D>(CommandBuffer, out bool added);
        if (added || frameChanged || animatedSprite.InvalidateTexture)
        {
            sprite2D.TexturePath = texturePath;
            sprite2D.InvalidateTexture = true;
        }

        animatedSprite.InvalidateTexture = false;
    }
}
