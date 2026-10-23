using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.Objects.Level.Rooms;

namespace Escapeaway.Source.Objects
{
    internal class Character
    {
        // Public variables
        public int X, Y, Width, Height;

        // Protected variables
        protected int resize = 1, defaultWidth, defaultHeight;
        protected Sprite sprite;

        // Animation variables
        Point sheetSize;
        protected float elapsed = 0;
        public float animSpeed = 150f;
        public int frame { get; private set; } = 0;
        int maxFrames;
        public bool flipped;

        public List<string> animation;
        protected List<int> startFrame, endFrame;

        // Controls
        public KeyboardState keyboard, previousKeyboard;
        public GamePadState gamepad, previousGamepad;

        public Character(Texture2D texture, Point location, Point size, Point sheetSize, Color color)
        {
            // Set variables
            X = location.X;
            Y = location.Y;

            if (texture != null) defaultWidth = sheetSize.X;
            else defaultWidth = size.X;

            defaultHeight = size.Y;
            this.sheetSize = sheetSize;
            UpdateSize();

            animation = new List<string>();
            startFrame = new List<int>();
            endFrame = new List<int>();

            // Create Sprite
            sprite = new Sprite(texture,                // Texture
                new Rectangle(new Point(X, Y),          // Position
                new Point(Width, Height)),              // Size
                new Rectangle(new Point(0, 0),          // Sprite Sheet Frame Position
                sheetSize),                             // Sprite Sheet Size
                color);                                 // Color
        }

        // Set bounds for Character
        public Rectangle Bounds
        {
            get
            {
                return new Rectangle(new Point(X, Y), new Point(Width, Height));
            }
        }

        public void Update(GameTime gameTime)
        {
            // Controls
            keyboard = Keyboard.GetState();
            gamepad = GamePad.GetState(PlayerIndex.One);

            // Override Update
            OnUpdate(gameTime);

            previousKeyboard = keyboard;
            previousGamepad = gamepad;
        }

        public virtual void OnUpdate(GameTime gameTime)
        {
        }

        public virtual void Draw(SpriteBatch spriteBatch)
        {
            // Update

            sprite.SetDestRect(new Rectangle(
                new Point(X, Y),
                new Point(Width * resize, Height * resize)));

            // Current Frame of Sprite Sheet
            sprite.SetSourceRect(new Rectangle(
                new Point(sheetSize.X * frame, 0),
                new Point(sheetSize.X, sheetSize.Y)));

            // Draw
            sprite.Draw(spriteBatch);
        }

        // Animate

        public void CreateAnimation(string name, int startFrame, int endFrame)
        {
            // Add Animation to Name List
            animation.Add(name);

            // Start and End Frames
            this.startFrame.Add(startFrame);
            this.endFrame.Add(endFrame);
        }

        public void PlayAnimation(string name)
        {
            // Select Animation
            int animNumber = animation.IndexOf(name);

            // Play Selected Animation
            PlayAnimation(startFrame[animNumber], endFrame[animNumber]);
        }

        // Private Play Animation
        // This plays the start and end frames of the animation.
        // Not to be publicly used because you only need the name to play an animation.
        private void PlayAnimation(int startFrame, int endFrame)
        {
            // Make Sure Frame is Updated to Animation
            if (frame < startFrame) frame = startFrame;

            // Update animation time using GameTime
            elapsed += (float)MainGame.gameTime.ElapsedGameTime.TotalMilliseconds;

            if (elapsed >= animSpeed)
            {
                // Update Frame
                frame++;

                // If Animation Finished
                if (frame > endFrame) frame = startFrame;

                elapsed = 0;
            }
        }

        public void SetSprite(Texture2D newTexture)
        {
            sprite.SetTexture(newTexture);
        }

        public void SetFrame(int newFrame)
        {
            frame = newFrame;
        }

        // Interaction

        public bool CollidesWith(Character collider)
        {
            // Colliding character is intersecting another character
            return Bounds.Intersects(collider.Bounds);
        }

        public bool CollidesWith(StaticSprite collider)
        {
            return Bounds.Intersects(collider.GetDestRect());
        }

        // Setters

        public void SetSize(int newSize)
        {
            resize = newSize;

            UpdateSize();
        }

        private void UpdateSize()
        {
            Width = defaultWidth * resize;
            Height = defaultHeight * resize;
        }

        public void SetColor(Color newColor)
        {
            sprite.SetColor(newColor);
        }

        public void SetLocation(Point point)
        {
            X = point.X;
            Y = point.Y;
        }

        // Controls

        public bool KeyPress(Keys key)
        {
            if (keyboard.IsKeyUp(key) && previousKeyboard.IsKeyDown(key))
            {
                return true;
            }
            else return false;
        }

        public bool KeyDown(Keys key)
        {
            if (keyboard.IsKeyDown(key))
            {
                return true;
            }
            else return false;
        }

        public bool ButtonPress(Buttons button)
        {
            if (gamepad.IsConnected)
            {
                if (gamepad.IsButtonUp(button) && previousGamepad.IsButtonDown(button))
                {
                    return true;
                }
                else return false;

            }
            else return false;
        }

        public bool ButtonDown(Buttons button)
        {
            if (gamepad.IsConnected)
            {
                if (gamepad.IsButtonDown(button))
                {
                    return true;
                }
                else return false;

            }
            else return false;
        }
    }
}