using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source;

namespace Escapeaway.Source.Objects
{
    internal class Camera
    {
        // Public Variables
        public int Width => target.Width;
        public int Height => target.Height;

        // Private Variables
        private readonly RenderTarget2D target;
        private readonly GraphicsDevice graphicsDevice;
        private Rectangle destRect;

        public Camera(GraphicsDevice graphicsDevice, int width, int height)
        {
            this.graphicsDevice = graphicsDevice;
            target = new RenderTarget2D(graphicsDevice, width, height);
        }

        public void SetDestRect()
        {
            var screenSize = graphicsDevice.PresentationParameters.Bounds;

            float scaleX = (float)screenSize.Width / target.Width;
            float scaleY = (float)screenSize.Height / target.Height;
            float scale = Math.Min(scaleX, scaleY);

            int newWidth = (int)(target.Width * scale);
            int newHeight = (int)(target.Height * scale);

            int posX = (screenSize.Width - newWidth) / 2;
            int posY = (screenSize.Height - newHeight) / 2;

            destRect = new Rectangle(posX, posY, newWidth, newHeight);
        }

        public void Activate()
        {
            graphicsDevice.SetRenderTarget(target);
            graphicsDevice.Clear(Color.Black);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            graphicsDevice.SetRenderTarget(null);
            graphicsDevice.Clear(Color.Black);
            spriteBatch.Begin(SpriteSortMode.Deferred,
                BlendState.AlphaBlend,
                SamplerState.PointClamp,
                DepthStencilState.None,
                RasterizerState.CullCounterClockwise);
            spriteBatch.Draw(target, destRect, Color.White);
            spriteBatch.End();
        }
    }
}