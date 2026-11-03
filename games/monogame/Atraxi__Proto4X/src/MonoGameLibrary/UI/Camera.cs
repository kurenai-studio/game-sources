using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary.Input;

namespace MonoGameLibrary.UI
{
    public class Camera
    {
        private Matrix cameraMatrix = Matrix.Identity;
        private const int CAMERA_SPEED = 100;

        public Matrix GetCameraTransform()
        {
            return cameraMatrix;
        }

        internal void Update(Rectangle viewportBounds, GameTime gameTime)
        {
            //TODO maybe this should be moved into UIManager to consolidate input detection? Or maybe instead I should implement stub APIs to isolate key codes for later rebinding support?
            var keyboard = InputManager.Instance.KeyboardInfo;
            var mouse = InputManager.Instance.MouseInfo;

            float cameraX = 0;
            float cameraY = 0;
            if (keyboard.IsKeyDown(Keys.Up))
            {
                cameraY -= (float)(CAMERA_SPEED * gameTime.ElapsedGameTime.TotalSeconds);
            }
            if (keyboard.IsKeyDown(Keys.Down))
            {
                cameraY += (float)(CAMERA_SPEED * gameTime.ElapsedGameTime.TotalSeconds);
            }
            if (keyboard.IsKeyDown(Keys.Left))
            {
                cameraX -= (float)(CAMERA_SPEED * gameTime.ElapsedGameTime.TotalSeconds);
            }
            if (keyboard.IsKeyDown(Keys.Right))
            {
                cameraX += (float)(CAMERA_SPEED * gameTime.ElapsedGameTime.TotalSeconds);
            }
            cameraMatrix *= Matrix.CreateTranslation((float)cameraX, (float)cameraY, 0);

            float cameraRotation = 0;
            if (keyboard.IsKeyDown(Keys.Z))
            {
                cameraRotation -= (float)double.DegreesToRadians(CAMERA_SPEED * gameTime.ElapsedGameTime.TotalSeconds);
            }
            if (keyboard.IsKeyDown(Keys.X))
            {
                cameraRotation += (float)double.DegreesToRadians(CAMERA_SPEED * gameTime.ElapsedGameTime.TotalSeconds);
            }
            
            cameraMatrix *= Matrix.CreateTranslation(-viewportBounds.Width / 2, -viewportBounds.Height / 2, 0) *
                Matrix.CreateRotationZ((float)cameraRotation) *
                Matrix.CreateTranslation(viewportBounds.Width / 2, viewportBounds.Height / 2, 0);


            //var scale = (float)Math.Pow(1.1f, mouse.ScrollWheelDelta / 120);
            float cameraZoom = 1;
            if (mouse.ScrollWheelDelta < 0)
            {
                cameraZoom *= 0.9f;
            }
            else if (mouse.ScrollWheelDelta > 0)
            {
                cameraZoom *= 1.1f;
            }
            cameraMatrix *= Matrix.CreateTranslation(-mouse.Position.X, -mouse.Position.Y, 0) *
                Matrix.CreateScale(cameraZoom, cameraZoom, 1) *
                Matrix.CreateTranslation(mouse.Position.X, mouse.Position.Y, 0);

            if (viewportBounds.Contains(mouse.Position))
            {
                //if(mouse.Position.X < 0)
            }
        }
    }
}