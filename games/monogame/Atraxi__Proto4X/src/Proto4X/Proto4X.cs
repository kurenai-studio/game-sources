using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Input;
using MonoGameLibrary.World;
using Proto4X.Systems;

namespace Proto4X
{
    public class Proto4X() : Core("Proto4X", 1920, 1080, false)
    {
        protected override GameWorld InitializeGameWorld()
        {
            return new GameWorld(0, 0, 1000, 1000);
        }

        protected override void OnInitialize()
        {
            SystemScheduler.Add(World, new MovementSystem());
            SystemScheduler.Add(World, new PlayerInputSystem(World));
        }

        protected override void LoadContent()
        {
            var scout = Content.Load<Texture2D>("Ships/ship_scout_32x32");
            var scoutId = SpriteLibrary.Add(scout);
            var station = Content.Load<Texture2D>("Stations/station_core_64x64");
            var stationId = SpriteLibrary.Add(station);

            World.AddEntity(EntityBuilder.CreateEntity()
                .With(new Position(new Vector2(50, 60), float.DegreesToRadians(90)))
                .With(new Drawable(scoutId, null))
                .With(new Motion(new Vector2(20, 40), default, 1f)));
        }

        protected override void OnUpdate(GameTime gameTime)
        {
            if (InputManager.Instance.KeyboardInfo.IsKeyDown(Keys.Escape))
            {
                Exit();
            }
        }

        protected override void OnDraw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);
        }
    }
}
