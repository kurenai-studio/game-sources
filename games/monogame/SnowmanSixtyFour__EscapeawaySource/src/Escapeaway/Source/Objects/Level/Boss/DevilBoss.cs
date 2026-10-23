using Escapeaway.Source.Objects.Level.Projectiles;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Escapeaway.Source.Objects.Level.Boss
{
    internal class DevilBoss : Boss
    {
        // Variables
        private Random random;

        // Sprite
        private Character devil;
        private Point
            size = new Point(80, 64),
            sheetSize = new Point(480, 64);

        // Health Bar
        private BossHealthBar healthBar;

        // Movement
        private bool movingUp = false;
        private float
            yVelocity = 0,
            gravity = 0.2f, maxMovementSpeed = 1.5f,

            // Animations
            maxUpHeight = 30, maxDownHeight = 34, // Flying
            jumpIncrement = 5, maxReach = 40; // Death
        private bool falling = false;

        // Properties
        private Point
            fightPosition = new Point(Global.resWidth - 100, 32);
        private bool
            movedOnscreen = false;

        // Projectiles
        private List<DevilFireball> animationBullets = new List<DevilFireball>();
        public List<DevilFireball> bullets = new List<DevilFireball>();

        private List<bool> hurtBullets = new List<bool>(); // Keep track of which bullets hurt

        // Random hurt variables for projectile
        private int randomHurt;
        private bool shouldHurt;

        // Timers
        private float
            animateTimer = 0f, createNewAnimation = 250f,
            bulletTimer = 0f, createNewBullet = 1000f,
            waitTimer = 0f, waitMax = 3300f;
        private bool
            startAttack = false, // Start Attack Process
            animateBullets = false, // Animate Bullets being Created
            createBullets = false; // Create Dodgable Bullets

        private int
            currentBullet = 0, // Counter for Interactive Bullets

            // Max Bullet Counts (Start from 1, not 0)
            maxAnimationBullets = 3, // Max Bullets in Animation
            maxBullets = 3; // Max Bullets Before Erasing First Created

        public DevilBoss(int health) : base(health)
        {
            // Initialize Variables
            random = new Random();

            // Set Boss

            devil = new Character(Global.devil, new Point(Global.resWidth, fightPosition.Y), sheetSize, size, Color.White);

            devil.CreateAnimation("default", 0, 0);
            devil.CreateAnimation("hurt", 1, 1);
            devil.CreateAnimation("staring", 2, 2);
            devil.CreateAnimation("shocked", 3, 3);
            devil.CreateAnimation("attack", 4, 5);

            healthBar = new BossHealthBar("The Devil");
        }

        public override void Reset()
        {
            // Reset Health
            base.Reset();

            // Reset Properties
            devil.SetLocation(new Point(Global.resWidth, fightPosition.Y));
            movedOnscreen = false;
            falling = false;

            bullets.Clear();
            animationBullets.Clear();

            startAttack = false;
            animateBullets = false;
            createBullets = false;
        }

        /// <summary>
        /// Moves the bullets back a certain amount of pixels. Useful when the player is respawning.
        /// </summary>
        /// <param name="amountToMove">The amount of pixels to move each bullet back by.</param>
        public void MoveBulletsAway(int amountToMove)
        {
            foreach (var bullet in bullets)
            {
                bullet.sprite.X += amountToMove;
            }
        }

        /// <summary>
        /// Parry the devil's bullet back into him.
        /// </summary>
        public void ParryBullet(DevilFireball bullet)
        {
            bullet.moving = false;
            bullet.parry = true;
        }

        private void HurtDevil()
        {
            // Calculate Next Damage Amount
            int damageDealt = random.Next(10, 25);

            // If Health is Above 0
            if (health > 0)
            {
                // Flicker Health Bar
                healthBar.Flicker();

                // Deal Damage to Health
                health -= damageDealt;
            }
        }

        public void Update(GameTime gameTime, Player player)
        {
            // Update Objects

            devil.Update(gameTime);

            healthBar.Update(gameTime, this);

            if (!defeated)
            {
                foreach (var bullet in bullets) bullet.Update(gameTime);
                foreach (var animationBullet in animationBullets) animationBullet.Update(gameTime);
            }

            // Defeat

            if (health <= 0) if (!defeated) defeated = true;

            if (defeated)
            {
                // Remove Bullets

                if (bullets.Count > 0 || animationBullets.Count > 0)
                {
                    startAttack = false;
                    createBullets = false;
                    animateBullets = false;

                    bullets.Clear();
                    animationBullets.Clear();
                }

                // Death Animation

                if (!falling)
                {
                    yVelocity = -jumpIncrement;

                    falling = true;
                }

                if (falling)
                {
                    if (yVelocity < maxReach) yVelocity += gravity;
                    else yVelocity = maxReach;
                }

                devil.Y += Convert.ToInt32(yVelocity);
            }
            else
            {
                // Flying Movement

                if (devil.Y < maxUpHeight) movingUp = false;
                if (devil.Y > maxDownHeight) movingUp = true;

                devil.Y += Convert.ToInt32(yVelocity);

                if (movingUp)
                {
                    if (yVelocity > -maxMovementSpeed) yVelocity -= gravity;
                    else yVelocity = -maxMovementSpeed;
                }
                if (!movingUp)
                {
                    if (yVelocity < maxMovementSpeed) yVelocity += gravity;
                    else yVelocity = maxMovementSpeed;
                }

                // If Player is in Center of Screen

                if (player.centered)
                {
                    // Intro to Boss Fight
                    if (!movedOnscreen)
                    {
                        if (devil.X > fightPosition.X)
                        {
                            devil.X--;
                        }
                        else
                        {
                            movedOnscreen = true;

                            devil.X = fightPosition.X;
                        }
                    }
                }

                // Set Variables after Onscreen
                if (movedOnscreen)
                {
                    // Start Attack
                    if (animationBullets.Count <= 0) startAttack = true;

                    // Projectiles
                    if (startAttack)
                    {
                        // Begin Animation
                        animateBullets = true;

                        // Set Flag to False
                        startAttack = false;
                    }
                }

                // Projectiles

                try
                {
                    // Animation Bullets
                    if (animateBullets)
                    {
                        // Create New Bullets
                        animateTimer += gameTime.ElapsedGameTime.Milliseconds;
                        if (animateTimer > createNewAnimation)
                        {
                            // Randomize if Bullet should Hurt
                            randomHurt = random.Next(0, 2);
                            if (randomHurt == 0) shouldHurt = false;
                            else shouldHurt = true;

                            hurtBullets.Add(shouldHurt);

                            // Add New Bullet to List
                            Point offset = new Point((devil.Width - 6), 30); // Offset for Creating Bullet
                            animationBullets.Add(new DevilFireball(new Point(devil.X + offset.X, fightPosition.Y + offset.Y), shouldHurt, true));
                            currentBullet++;

                            SFX.projectile.Play();

                            // Reset Timer
                            animateTimer = 0f;
                        }

                        // When Max Bullets in Animation Reached
                        if (animationBullets.Count > maxAnimationBullets)
                        {
                            // End Animation
                            animateBullets = false;
                            currentBullet = 0;

                            // Start Creating Interactive Bullets
                            createBullets = true;
                        }
                    }

                    // Interactive Bullets
                    if (createBullets)
                    {
                        bulletTimer += gameTime.ElapsedGameTime.Milliseconds;
                        if (bulletTimer > createNewBullet)
                        {
                            // Set if Bullet should Hurt from Animation
                            bool shouldHurt = hurtBullets[currentBullet];

                            // Create New Bullet
                            bullets.Add(new DevilFireball(new Point(Global.resWidth, 142), shouldHurt, false));
                            currentBullet++;

                            // Remove Bullet Once Offscreen
                            int index = 0;
                            foreach (var bullet in bullets)
                            {
                                index++;
                                if (bullet.sprite.X < -bullet.sprite.Width) bullets.RemoveAt(index);
                            }

                            // Stop Creating Bullets at Max Amount
                            if (bullets.Count > maxBullets)
                            {
                                createBullets = false;

                                currentBullet = 0;
                            }

                            // Reset Timer
                            bulletTimer = 0f;
                        }
                    }

                    // Restart Attack
                    if (!animateBullets && !createBullets && animationBullets.Count > 0)
                    {
                        waitTimer += gameTime.ElapsedGameTime.Milliseconds;

                        if (waitTimer > waitMax)
                        {
                            // Reset Bullets
                            bullets.Clear();
                            animationBullets.Clear();

                            // Reset Hurt Pattern
                            if (hurtBullets.Count > 0) hurtBullets.Clear();

                            // Restart Attack
                            startAttack = true;

                            // Reset Timer
                            waitTimer = 0f;
                        }
                    }

                    // When Hurt
                    foreach (var bullet in bullets)
                    {
                        // Parried Bullet
                        if (bullet.parry)
                        {
                            // Touching Devil
                            if (devil.CollidesWith(bullet.sprite))
                            {
                                bullet.gone = true;

                                HurtDevil();
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    Debug.Print("Error!\n" + e);
                }
            }

            // Animations

            if (defeated)
            {
                devil.PlayAnimation("shocked");
            }
            else
            {
                if (animateBullets) devil.PlayAnimation("attack");

                else
                {
                    bool hurt = false;
                    foreach (var bullet in bullets)
                    {
                        if (bullet.parry)
                        {
                            if (devil.CollidesWith(bullet.sprite))
                            {
                                hurt = true;
                            }
                        }
                    }

                    if (hurt) devil.PlayAnimation("hurt");
                    else devil.PlayAnimation("default");
                }
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw Character
            devil.Draw(spriteBatch);

            // Draw Projectiles
            foreach (var bullet in bullets) bullet.Draw(spriteBatch);
            foreach (var animationBullet in animationBullets) animationBullet.Draw(spriteBatch);

            // Draw Health Bar
            if (movedOnscreen) if (!defeated) healthBar.Draw(spriteBatch);
        }
    }
}
