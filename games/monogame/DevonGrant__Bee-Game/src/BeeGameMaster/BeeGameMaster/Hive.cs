using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
//a hive class
//default position is at bottom of screen, but x position can be adjusted in constructor
//update method: if collision is detected, health decreases
namespace BeeGameMaster
{
    class Hive : Dies
    {
        Texture2D texture;
        Rectangle rect;
        int health = 1000;
        private bool isDead = false;
        private int winHeight;

        public Texture2D Texture { get => texture; set => texture = value; }
        public Rectangle Rect { get => rect; set => rect = value; }
        public int Health { get => health; set => health = value; }
        public int X { get => rect.X; set => rect.X = value; }
        public int Y { get => rect.Y; set => rect.Y = value; }
        public int WinHeight { get => winHeight; set => winHeight = value; }
        public bool IsDead { get => isDead; set => isDead = value; }

        //Constructor
        public Hive(Texture2D newTexture, int x, int width, int wHeight)
        {
            texture = newTexture;
            winHeight = wHeight;
            rect = new Rectangle(x, 0, texture.Width / 4, texture.Height / 4);
            Y = winHeight - rect.Height;
        }

        public Hive(Texture2D newTexture, int wWidth, int wHeight)
        {
            texture = newTexture;
            winHeight = wHeight;
            rect = new Rectangle(0, 0, wWidth, texture.Height / 4);
            Y = winHeight - rect.Height;
        }

        //Methods
        public void Update(GameTime gameTime)
        {
            if (health <= 0)
            {
                isDead = true;
            }
        }
    }
}
