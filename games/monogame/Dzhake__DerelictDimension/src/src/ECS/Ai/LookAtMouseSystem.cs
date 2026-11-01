using DerelictDimension.ECS.PhysicsModule;
using Monod.ECS;
using Monod.ECS.DefaultComponents;
using Monod.Graphics;
using Monod.InputModule;
using Monod.MathModule;
using Monod.Utils.Extensions;
using MonoGame.Extended;
using SDL3;
using System;

namespace DerelictDimension.ECS.Ai;

public class LookAtMouseSystem : TagSystem<LookAtMouseTag>
{
    public CommandBuffer cb;
    public static bool RelativeRotation = false;

    protected override void OnAddStore(EntityStore store)
    {
        cb = store.GetCommandBuffer();
        cb.ReuseBuffer = true;
        base.OnAddStore(store);
    }

    protected override void OnRemoveStore(EntityStore store)
    {
        cb.ReturnBuffer();
        base.OnRemoveStore(store);
    }

    protected override void OnUpdateGroup()
    {
        SDL.SDL_SetWindowRelativeMouseMode(Renderer.Window.Handle, RelativeRotation);
        foreach (var entity in Query.Entities)
        {
            ref var transform = ref entity.Data.Ensure<Transform2D>(cb);
            float rotation;
            if (RelativeRotation)
            {
                SDL.SDL_GetRelativeMouseState(out float x, out float y);
                var mouseOffset = new Vector2(x, y);
                float rotspeed = 0.003f; //TODO (QOL:low) make this a setting 'mouse sensitivity'
                rotation = (transform.Rotation + mouseOffset.X * rotspeed) % (MathF.Tau);
            }
            else
            {
                Vector2 mousePos = Renderer.WindowSize / 2;
                var mouseOffset = Input.MousePos() - (entity.GetWorldPos() * Physics.PixelsInMeter);
                rotation = mouseOffset.ToAngle();
            }

            if (MathF.Abs(rotation - transform.Rotation) > MathM.Epsilon)
            {
                transform.Rotation = rotation;
                entity.SetTransformDirtyRecursive();
            }
        }

        base.OnUpdateGroup();
        cb.Playback();
    }

}
