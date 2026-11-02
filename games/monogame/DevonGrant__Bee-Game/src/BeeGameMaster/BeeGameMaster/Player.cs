using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BeeGameMaster
{
    public class Player : Shoots
    {
        Texture2D texture;
        Rectangle rect;
        Projectile stinger;
        List<Projectile> stingers = new List<Projectile>();
        int health = 1;
        int speed = 5;
        int damage = 1;
        private int levelScore;
        private int totalScore;
        private int winWidth;
        private int winHeight;
        //while specialshots are activated, the added projectile in Game1 for player1 will be special
        private bool specialShots;
        private bool slowTime;

        public Texture2D Texture { get => texture; set => texture = value; }
        public Rectangle Rect { get => rect; set => rect = value; }
        public int Health { get => health; set => health = value; }
        public int X { get => rect.X; set => rect.X = value; }
        public int Y { get => rect.Y; set => rect.Y = value; }
        public int LevelScore { get => levelScore; set => levelScore = value; }
        public int TotalScore { get => totalScore; set => totalScore = value; }
        public int WinWidth { get => winWidth; set => winWidth = value; }
        public Projectile Stinger { get => stinger; set => stinger = value; }
        internal List<Projectile> Stingers { get => stingers; set => stingers = value; }
        public int WinHeight { get => winHeight; set => winHeight = value; }
        public int Damage { get => damage; set => damage = value; }
        public bool SpecialShots { get => specialShots; set => specialShots = value; }
        public bool SlowTime { get => specialShots; set => specialShots = value; }

        //Constructor
        public Player(Texture2D newTexture, int x, int y, int wWidth, int wHeight)
        {
            texture = newTexture;
            winHeight = wHeight;
            rect = new Rectangle(x, y, texture.Width / 4, texture.Height / 4);
            winWidth = wWidth;
            specialShots = false;
            slowTime = false;
        }

        //Methods
        //Centers the player sprite
        public void Center()
        {
            X = (winWidth - rect.Width) / 2;
        }

        public void Update(GameTime gameTime)
        {
            KeyboardState state = Keyboard.GetState();
            //Tracks urser input
            if (state.IsKeyDown(Keys.LeftShift))
            {
                speed = 12;
            }
            else
            {
                speed = 8;
            }

            //Player Movement
            if ((state.IsKeyDown(Keys.Left)) || (state.IsKeyDown(Keys.A)))
            {
                X -= speed;
            }
            if ((state.IsKeyDown(Keys.Right)) || (state.IsKeyDown(Keys.D)))
            {
                X += speed;
            }

            //Window Wrapping
            if (X < 0)
            {
                X = winWidth - Rect.Width;
            }
            else if (X > winWidth - Rect.Width)
            {
                X = 0;
            }
        }
    }
}
