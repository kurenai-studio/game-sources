using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Snake.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace Snake.Controllers
{
    class ControllerBiscuit
    {

        private readonly ModelBiscuit _modelBiscuit;
        private static ControllerSnake _controllerSnake;

        public ControllerBiscuit(ContentManager content, GraphicsDeviceManager graphics)
        {
            _modelBiscuit = new ModelBiscuit(content, graphics);
        }

        public void setControllerSnake(ref ControllerSnake controllerSnake)
        {
            _controllerSnake = controllerSnake;
        }
        public Rectangle RectBiscuit { get; private set; }

        public int Score { get; private set; }

        public void Update(GameTime gameTime, GraphicsDeviceManager graphics)
        {
            _modelBiscuit.Collided = _controllerSnake.Collided;
            _modelBiscuit.Update(gameTime, graphics);
            RectBiscuit = _modelBiscuit.RectBiscuit;
            Score = _modelBiscuit.Score;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            _modelBiscuit.Draw(spriteBatch);
        }

    }
}
