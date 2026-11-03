using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Input;
using MonoGameLibrary.Systems.Infrastructure;
using MonoGameLibrary.World;
using System.Collections.Generic;

namespace Proto4X.Systems
{
    public class PlayerInputSystem(GameWorld gameWorld) : IUpdateSystem
    {
        private const int ACCELERATION = 100;
        private const int ANGULAR_ACCELERATION = 100;
        private int selectedEntityId = 0;

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => [ComponentRef.Of<Position>(), ComponentRef.Of<Motion>()];

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            if (selectedEntityId == -1 || !gameWorld.TryGetComponent<Position>(selectedEntityId, out var position))
            {
                return;
            }

            var newAcceleration = Vector2.Zero;
            var newAngularAcceleration = 0f;
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.W)) newAcceleration += new Vector2(0, -1);
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.S)) newAcceleration += new Vector2(0, 1);
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.A)) newAcceleration += new Vector2(-1, 0);
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.D)) newAcceleration += new Vector2(1, 0);
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.Q)) newAngularAcceleration -= float.DegreesToRadians(ANGULAR_ACCELERATION);
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.E)) newAngularAcceleration += float.DegreesToRadians(ANGULAR_ACCELERATION);
            if (newAcceleration != Vector2.Zero)
            {
                newAcceleration.Rotate(position.Rotation);
                newAcceleration = Vector2.Normalize(newAcceleration) * ACCELERATION;
            }

            gameWorld.MutateComponent(selectedEntityId, (ref Motion motion) =>
            {
                motion.Acceleration = newAcceleration;
                motion.AngularAcceleration = newAngularAcceleration;
            });
        }
    }
}
