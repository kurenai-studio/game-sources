using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Audio;
using Escapeaway.Source.Objects;
using Escapeaway.Source.Objects.Level.Particles;
using Escapeaway.Source.Objects.Level.Rooms;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.Objects.Level.Boss;
using System.Diagnostics;

namespace Escapeaway.Source.Objects.Level
{
    internal class Player : Character
    {
        // Game Variables
        public int
            lives = 0,
            score = 0;
        private Point startingPosition;

        // Screen
        public bool
            moving = false,
            speedUpOverTime = false,
            slowingDown = false,
            centered = false, // For Final Boss Room
            gameOver = false;
        private bool
            blocked = false,
            cantSlide = true;
        public bool reachedEnd = false;

        // Properties
        private RoomLayout room;
        public static Point
            size = new Point(32, 32),
            sheetSize = new Point(320, 32),

            slidingSize = new Point(32, 16);

        private int
            // Default Variables
            runSpeed = 0,
            yVelocity = 0,

            // Running Speeds
            defaultRunSpeed = 0,
            slowRunSpeed = 1,
            bossRunSpeed = 2,

            // Jumping
            jumpIncrement = 12,
            maxJumpHeight = 65,
            gravity = 1,

            // Sliding
            slideCounter = 0,
            slideStart = 30;

        // Conditions
        private bool
            jumping = false, aboveGround = false,
            sliding = false;

        // Timers
        private float
            // Visuals
            flickerTimer = 0f,
            framesUntilFlicker = 90f,

            // Events
            scorePenalizeTimer = 0f, startRunningTimer = 0f,
            framesUntilScorePenalized = 260f, timeUntilMovingAgain = 1000f,

            // SFX
            footstepSfxTimer = 0f, slowDownSfxTimer,
            framesToPlayFootstepSfx = 180f, framesToPlaySlowDownSfx = 40f;
        private bool
            flickering = false,
            shouldFlicker = false, countdownRun = false;

        // Respawn Timer Text
        private Text respawnTimer;

        // Checks
        private StaticSprite
            keepSlidingCheck, // Prevent slide from ending while under wall
            canSlideCheck; // If slide is possible

        // Particles
        private List<DustParticle> slowParticles = new List<DustParticle>();
        private int dustParticleLimit = 4;

        private List<DustParticle> jumpParticles = new List<DustParticle>();

        public Player(Texture2D spriteSheet, Point location, Color color, int startingLives) : base(spriteSheet, location, sheetSize, size, color)
        {
            // Set Variables
            startingPosition = location;
            lives = startingLives;

            // Set Text
            respawnTimer = new Text(Global.defaultFont, "", Vector2.Zero, CustomColor.White, 1.0f, false);

            // Set Movement Checks
            keepSlidingCheck = new StaticSprite(null, new Rectangle(0, 0, 20, 20), Color.Red * 0.5f);
            canSlideCheck = new StaticSprite(null, new Rectangle(0, 0, 20, 20), Color.Lime * 0.5f);

            // Create Animations

            CreateAnimation("default", 0, 3);
            CreateAnimation("running", 4, 6);
            CreateAnimation("jumping", 7, 7);
            CreateAnimation("falling", 8, 8);
            CreateAnimation("sliding", 9, 9);
        }

        public void SetRoom(RoomLayout newRoom)
        {
            room = newRoom;
        }

        private void NewSlowDownParticle()
        {
            // Delete Previous Particles
            if (slowParticles.Count > dustParticleLimit) slowParticles.RemoveAt(0);

            // Create New Particle
            slowParticles.Add(new DustParticle(this));
        }

        private void CreateJumpParticles()
        {
            // In Boss Room
            if (centered && !slowingDown) // Regular Speed
            {
                int particleX = (this.X + 4);
                int particleY = (this.Y + this.Height - 8);

                jumpParticles.Add(new DustParticle(particleX, particleY, true));
                jumpParticles.Add(new DustParticle(particleX, particleY, false));
            }

            else if (centered && slowingDown) // Slowing Down
            {
                int particleY = (this.Y + this.Height - 8);

                jumpParticles.Add(new DustParticle(this.X, particleY, true));
                jumpParticles.Add(new DustParticle(this.X, particleY, false));
            }

            // In any other room
            else
            {
                jumpParticles.Add(new DustParticle(this, true));
                jumpParticles.Add(new DustParticle(this, false));
            }
        }

        /// <summary>
        /// Resets the player to its starting state. Good for level resets.
        /// </summary>
        public void Reset()
        {
            ClearParticles();

            // Stop Moving (wait for player input)
            moving = false;
            centered = false;

            // Reset Position
            X = startingPosition.X;
            Y = startingPosition.Y;

            // Reset Values
            blocked = false;
            cantSlide = true;

            Width = size.X;
            Height = size.Y;

            startRunningTimer = 0f;
            countdownRun = false;
            
            flickering = false;
            shouldFlicker = false;
        }

        private void LoseLife()
        {
            // Reset Player
            Reset();

            // Begin Flicker and Auto Run Events
            shouldFlicker = true;
            countdownRun = true;

            // Take a life
            if (lives > 0) lives--;
            // Game Over
            else
            {
                gameOver = true;
            }
        }

        /// <summary>
        /// Lose a life during a boss fight.
        /// </summary>
        private void LoseLifeDuringBoss()
        {
            LoseLife();

            centered = true;
        }

        /// <summary>
        ///  Start moving the player. Useful for respawning or starting the level.
        /// </summary>
        private void StartMoving()
        {
            moving = true;
            cantSlide = false;
        }

        private void ClearParticles()
        {
            slowParticles.Clear();
            jumpParticles.Clear();
        }

        public void SetSpeed(bool endless, int currentScreen)
        {
            if (endless)
            {
                if (currentScreen > 198)
                {
                    defaultRunSpeed = 5;
                }
                else if (currentScreen > 98)
                {
                    defaultRunSpeed = 4;
                }
                else
                {
                    defaultRunSpeed = 3;
                }
            }
            else
            {
                defaultRunSpeed = 3;
            }
        }

        public override void OnUpdate(GameTime gameTime)
        {
            // Prevent an illegal score
            if (score < 0) score = 0;

            // Prevent a huge gigantic score (from making the HUD look bad!)
            if (score > Global.maxScore) score = Global.maxScore;

            // Intro
            if (!moving)
            {
                // Animate Player
                PlayAnimation("default");
                animSpeed = 70;

                // Hide Particles
                ClearParticles();

                // Start Movement
                if (!countdownRun)
                {
                    if (KeyPress(Keys.Right)
                        || ButtonPress(Buttons.LeftThumbstickRight) || ButtonPress(Buttons.DPadRight))
                    {
                        StartMoving();
                    }
                }
            }

            // Flicker Effect after Respawning
            if (shouldFlicker)
            {
                flickerTimer += gameTime.ElapsedGameTime.Milliseconds;
                if (flickerTimer > framesUntilFlicker)
                {
                    flickering = !flickering;

                    flickerTimer = 0f;
                }
            }

            // Timer until Running Again
            if (countdownRun)
            {
                // Update Timer Variable
                startRunningTimer += gameTime.ElapsedGameTime.Milliseconds;

                // Update Display Text
                respawnTimer.setPosition(new Vector2(this.X + 14, this.Y - 16)); // Place above Player

                if (startRunningTimer > timeUntilMovingAgain - (timeUntilMovingAgain / 4)) respawnTimer.setText("1");
                else if (startRunningTimer > (timeUntilMovingAgain / 2)) respawnTimer.setText("2");
                else if (startRunningTimer > (timeUntilMovingAgain / 4)) respawnTimer.setText("3");

                // When Timer is Up
                if (startRunningTimer > timeUntilMovingAgain)
                {
                    // Stop Timer Flag
                    countdownRun = false;

                    // Stop Flickering
                    shouldFlicker = false;
                    flickering = false; // Failsafe if the flicker effect somehow leaves the player invisible

                    // Start Moving Again
                    StartMoving();

                    // Reset Display Text
                    respawnTimer.setText("");

                    // Reset Timer
                    startRunningTimer = 0f;
                }
            }

            // Movement
            if (moving)
            {
                // Movement Checks
                keepSlidingCheck.SetDestRect(new Rectangle(this.X, this.Y - 23, 20, 20));
                
                if (!sliding) canSlideCheck.SetDestRect(new Rectangle(this.X + 23, this.Y + 22, 16, 16));
                else canSlideCheck.SetDestRect(new Rectangle(this.X + 23, this.Y, 16, 16));

                // Lose a Life
                if (X < (Global.resWidth - this.Width))
                {
                    if (Y > Global.resHeight)
                    {
                        LoseLife();
                    }
                }

                // Jump
                if (!sliding && !jumping)
                {
                    if (KeyDown(Keys.Z)
                        || ButtonDown(Buttons.B) || ButtonDown(Buttons.A))
                    {
                        yVelocity = -jumpIncrement;

                        jumping = true;
                        aboveGround = true;

                        SFX.jump.Play();
                    }
                }

                // Gravity
                if (X >= 0 || X < Global.resWidth)
                {
                    if (jumping)
                    {
                        if (yVelocity < maxJumpHeight) yVelocity += gravity;
                        else yVelocity = maxJumpHeight;
                    }
                }

                // Update Y Position
                Y += yVelocity;

                // Room Collision
                foreach (var sprite in room.ground.sprites)
                {
                    // If Not Touching Wall
                    if (sliding || !jumping)
                    {
                        if (!(CollidesWith(sprite)))
                        {
                            blocked = false;
                        }
                    }

                    // Keep Slide Going
                    if (keepSlidingCheck.GetDestRect().Intersects(sprite.GetDestRect()))
                    {
                        if (sliding && slideCounter <= 5)
                        {
                            slideCounter++;
                        }
                    }

                    // When Touching Ground / Wall
                    if (CollidesWith(sprite))
                    {
                        // Place Player on Ground
                        if (yVelocity > 0 &&
                            Y <= sprite.GetDestRect().Y)
                        {
                            // Set Y Position
                            Y = sprite.GetDestRect().Y - Height;

                            // Create Jump Particles
                            if (jumping && aboveGround)
                            {
                                CreateJumpParticles();
                                aboveGround = false;
                            }

                            // Set Y Velocity
                            yVelocity = 0;

                            // Stop Jump
                            jumping = false;

                            // Don't End Collision Until Player Stops Touching Sprite
                            break;
                        }

                        // Prevent Slide
                        if (canSlideCheck.GetDestRect().Intersects(sprite.GetDestRect())) cantSlide = true;
                        else cantSlide = false;

                        // Block Player if Touching Wall
                        if (X >= sprite.GetDestRect().X - Width)
                        {
                            blocked = true;
                        }
                        else
                        {
                            blocked = false;
                        }
                    }
                    // Player is not Touching Ground
                    else
                    {
                        // Apply Gravity
                        jumping = true;
                    }
                }

                // Footstep SFX
                footstepSfxTimer += gameTime.ElapsedGameTime.Milliseconds;
                if (!jumping)
                {
                    if (footstepSfxTimer > framesToPlayFootstepSfx)
                    {
                        // Play Footstep SFX
                        if (!sliding && !blocked && !slowingDown) SFX.footsteps.Play();

                        // Reset Timer
                        footstepSfxTimer = 0f;
                    }
                }

                // Slowing Down SFX
                slowDownSfxTimer += gameTime.ElapsedGameTime.Milliseconds;
                if (KeyDown(Keys.Left)
                    || ButtonDown(Buttons.LeftThumbstickLeft) || ButtonDown(Buttons.DPadLeft))
                {
                    if (slowDownSfxTimer > framesToPlaySlowDownSfx)
                    {
                        if (!jumping && !blocked)
                        {
                            // Play SFX
                            SFX.skid.Play();

                            // Create new Dust
                            NewSlowDownParticle();
                        }

                        slowDownSfxTimer = 0f;
                    }

                    slowingDown = true;
                }
                else
                {
                    slowingDown = false;
                }

                // Movement Speed
                if (blocked) runSpeed = 0;
                else
                {
                    // Slow Down
                    if (slowingDown && !jumping) // Only works when not jumping
                    {
                        runSpeed = slowRunSpeed;
                    }

                    // Default Speed
                    else
                    {
                        runSpeed = defaultRunSpeed;
                    }
                }

                // When Not Centered Onscreen
                if (!centered)
                {
                    // Move Right
                    if (!blocked) X += runSpeed;

                    // Penalize Score while Blocked
                    else
                    {
                        scorePenalizeTimer += gameTime.ElapsedGameTime.Milliseconds;

                        // While Not Jumping
                        if (!aboveGround)
                        {
                            // Penalize Score
                            if (scorePenalizeTimer > framesUntilScorePenalized)
                            {
                                if (score > 0) score--;

                                scorePenalizeTimer = 0f;
                            }
                        }

                        // If Jumping
                        else
                        {
                            // Reset Timer Event
                            scorePenalizeTimer = 0f;
                        }
                    }
                }

                // Centered Onscreen
                else
                {
                    // Move Backwards when Slowing Down
                    if (slowingDown)
                    {
                        if (X >= 1) // Prevent Player from Going Offscreen
                        {
                            X -= bossRunSpeed;
                        }
                    }

                    // Move Slowly to Center
                    else
                    {
                        X += bossRunSpeed;
                    }
                }

                // Slide
                if (!cantSlide && !aboveGround)
                {
                    if (!sliding && !jumping)
                    {
                        if (KeyDown(Keys.Down)
                        || ButtonDown(Buttons.DPadDown) || ButtonDown(Buttons.LeftThumbstickDown))
                        {
                            SFX.slide.Play();
                        }
                    }

                    if (!jumping)
                    {
                        if (KeyDown(Keys.Down)
                        || ButtonDown(Buttons.DPadDown) || ButtonDown(Buttons.LeftThumbstickDown))
                        {
                            {
                                // Set Sliding Timer
                                if (!sliding) slideCounter = slideStart;

                                // Start Sliding
                                sliding = true;

                                if (Height != slidingSize.Y)
                                {
                                    // Update Size
                                    Width = slidingSize.X;
                                    Height = slidingSize.Y;
                                    Y += slidingSize.Y;
                                }
                            }
                        }
                    }
                }
                else slideCounter = 0;

                if (sliding)
                {
                    // Sliding Timer
                    if (slideCounter > 1) slideCounter--;
                    else
                    {
                        if (!KeyDown(Keys.Down)
                            && !ButtonDown(Buttons.DPadDown) && !ButtonDown(Buttons.LeftThumbstickDown))
                        {
                            slideCounter = 0;
                        }
                    }

                    // When Sliding is Finished
                    if (slideCounter <= 0)
                    {
                        // Reset Size
                        Width = size.X;
                        Height = size.Y;
                        Y -= slidingSize.Y;

                        // Stop Sliding
                        sliding = false;
                    }
                }

                // Reaching End of Screen
                if (X > Global.resWidth)
                {
                    reachedEnd = true;

                    // Prevent Player From Leaving Screen
                    if (reachedEnd) X = 0 - Width;

                    // Make Sure Player Doesn't Fall
                    if (!sliding) Y = startingPosition.Y;
                    else Y = startingPosition.Y + slidingSize.Y;

                    // Reset Particles
                    ClearParticles();
                }

                // Update Particles
                foreach (var slowDust in slowParticles) slowDust.Update(gameTime);
                foreach (var jumpDust in jumpParticles) jumpDust.Update(gameTime);

                // If in Boss Room
                if (centered && slowingDown)
                {
                    // Speed up Slowdown Particle Movement
                    foreach (var slowDust in slowParticles)
                    {
                        int fasterMoveSpeed = 5;
                        if (slowDust.pixelsToMove != fasterMoveSpeed)
                        {
                            slowDust.pixelsToMove = fasterMoveSpeed;
                        }
                    }
                }
                // Regular Speed
                else
                {
                    foreach (var slowDust in slowParticles)
                    {
                        int regularMoveSpeed = 1;
                        if (slowDust.pixelsToMove != regularMoveSpeed)
                        {
                            slowDust.pixelsToMove = regularMoveSpeed;
                        }
                    }
                }

                // Animate Player
                if (moving)
                {
                    if (!jumping)
                    {
                        if (!sliding)
                        {
                            if (blocked)
                            {
                                PlayAnimation("default");
                                animSpeed = 70;
                            }
                            else if (slowingDown)
                            {
                                PlayAnimation("falling");
                            }
                            else
                            {
                                PlayAnimation("running");
                                animSpeed = 30;
                            }
                        }
                        else
                        {
                            PlayAnimation("sliding");
                        }
                    }
                    else
                    {
                        if (yVelocity < 0)
                        {
                            PlayAnimation("jumping");
                        }
                        else
                        {
                            if (aboveGround) PlayAnimation("falling");
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Update the player during a boss fight.
        /// </summary>
        public void BossFight(DevilBoss devil)
        {
            if (moving)
            {
                // Projectiles
                foreach (var bullet in devil.bullets)
                {
                    // Allow Bullets to Move
                    if (!bullet.moving) bullet.moving = true;

                    // If Player Touches Bullet
                    if (CollidesWith(bullet.sprite))
                    {
                        // Not Sliding
                        if (!sliding)
                        {
                            if (bullet.hurts)
                            {
                                LoseLifeDuringBoss();
                            }

                            else
                            {
                                if (!bullet.parry)
                                {
                                    LoseLifeDuringBoss();
                                }
                            }    
                        }

                        // Sliding
                        else
                        {
                            // Hurts
                            if (bullet.hurts)
                            {
                                LoseLifeDuringBoss();
                            }

                            // Can Parry
                            else
                            {
                                devil.ParryBullet(bullet);
                            }
                        }
                    }
                }
            }

            // Stop Bullets when Lost a Life
            else
            {
                foreach (var bullet in devil.bullets)
                {
                    // Stop Bullet Movement
                    if (bullet.moving) bullet.moving = false;

                    // Collision during Respawn
                    int
                        amountToMove = 50, // Amount to move Bullet back by
                        radius = 40; // Radius around player to remove bullets
                    if (CollidesWith(bullet.sprite)
                        || bullet.sprite.X >= this.X - radius && bullet.sprite.X <= this.Width + radius)
                    {
                        // Move Bullets away from Player
                        devil.MoveBulletsAway(amountToMove);
                    }
                }
            }
        }

        public void Endless(FollowerBoss follower)
        {
            if (this.CollidesWith(follower.sprite))
            {
                LoseLife();

                follower.MovePositionBack();
            }
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            // Draw Character
            if (!flickering) base.Draw(spriteBatch);

            // Draw Particles
            foreach (var slowDust in slowParticles) slowDust.Draw(spriteBatch);
            foreach (var jumpDust in jumpParticles) jumpDust.Draw(spriteBatch);

            // Draw Respawn Timer
            if (countdownRun) respawnTimer.Draw(spriteBatch);

            // Debug Mode
            if (Global.debug)
            {
                // Movement Checks
                keepSlidingCheck.Draw(spriteBatch);
                canSlideCheck.Draw(spriteBatch);
            }
        }
    }
}
