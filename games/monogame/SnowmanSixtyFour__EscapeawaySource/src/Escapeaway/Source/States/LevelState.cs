using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.Objects.Level;
using Escapeaway.Source.Objects.Level.Particles;
using Escapeaway.Source.Objects.Level.Background;
using Escapeaway.Source.Objects.Level.Rooms;
using Escapeaway.Source.Objects.Level.Background.Cutscene;
using Escapeaway.Source.Objects.Level.Boss;
using Microsoft.Xna.Framework.Media;

namespace Escapeaway.Source.States
{
    internal class LevelState : State
    {
        RoomLayout roomLayout;
        FirstRoomDisclaimer roomDisclaimer;

        UnderdepthsBackground levelBackground;

        FirstRoomDevil firstRoomDevil;
        BackgroundDevil backgroundDevil;

        FollowerBoss follower;
        DevilBoss devil;

        Player player;

        LevelEndOverlay endOverlay;
        PauseOverlay pauseOverlay;
        HUD hud;

        public bool endless;

        private int defaultLives = 3;

        /*
         * currentScreen keeps track of the current Room the Player is in.
         * This is VERY useful for updating the room layout, player variables, and so on.
         * 
         * 0 = Room 1
         * 99 = Room 11
         * etc, subtract 1 from the Room you wish to apply code in
         * 
         * */

        public int
            currentScreen = 0,
            screenWithBackgroundDevil = 49,
            
            randomScreenColor = 0;
        private Random random;
        private Color screenColor = CustomColor.Red;

        private List<HeatParticle> heatParticles = new List<HeatParticle>();
        private float
            heatParticleTimer = 0f,
            timeBeforeNewHeatParticle = 360f;
        int heatParticleLimit = 14;

        public LevelState()
        {
            // Set Variables
            random = new Random();

            // Initialize Level
            roomLayout = new RoomLayout();
            roomDisclaimer = new FirstRoomDisclaimer();

            levelBackground = new UnderdepthsBackground();

            firstRoomDevil = new FirstRoomDevil(new Point(32, 76));
            backgroundDevil = new BackgroundDevil();

            devil = new DevilBoss(200);
            follower = new FollowerBoss();

            player = new Player(Global.player, new Point(8, 128), Color.White, defaultLives);

            endOverlay = new LevelEndOverlay();

            // HUD
            hud = new HUD();
            pauseOverlay = new PauseOverlay();
        }

        /// <summary>
        /// Generate heat particles for the level background.
        /// </summary>
        private void GenerateHeat()
        {
            heatParticles.Add(new HeatParticle(new Point(random.Next(0, (Global.resWidth - 8)), Global.resHeight)));
        }

        /// <summary>
        /// Resets the level back to a state in which the game hasn't started yet.
        /// </summary>
        public void ResetLevel()
        {
            // Reset Player
            player.Reset();
            player.X = 172; // Make sure position in first room is ahead of devil

            // Reset Objects
            firstRoomDevil.Reset();

            // Endless Mode Properties
            if (this.endless)
            {
                // Reset Follower
                follower.MovePositionBack();
            }

            // Reset Particles
            heatParticles.Clear();

            // Reset Foreground
            endOverlay.Reset();
        }

        /// <summary>
        /// Resets the game's level state all the way back to room 1, with a screen value of 0.
        /// </summary>
        public void GoBackToFirstRoom()
        {
            // Reset Screen
            currentScreen = 0;
            roomLayout.GoToFirstRoom();

            player.reachedEnd = false;

            this.screenColor = CustomColor.Red;

            firstRoomDevil.Show();
            backgroundDevil.Reset();

            follower.Reset();
            devil.Reset();

            // Reset Player Values (score, lives, etc)
            player.lives = defaultLives;
            player.score = 0;

            // Show Disclaimer
            roomDisclaimer.visible = true;

            // Reset Room
            ResetLevel();
        }

        public override void OnUpdate(GameTime gameTime, Main main)
        {
            // Set Global Variables
            if (endless != main.endless) endless = main.endless;

            // While Unpaused
            if (!Global.paused)
            {
                // Update Level
                roomLayout.Update(gameTime, this.screenColor, player);
                roomDisclaimer.Update(gameTime, player);

                levelBackground.Update(gameTime, this.screenColor);

                endOverlay.Update(gameTime);

                // When Game Won
                if (endOverlay.isCentered)
                {
                    main.win.SetScore(player.score);
                    main.title.SetHighscore();

                    SwitchState(main.win);

                    endOverlay.Reset();
                }

                // Update Enemies
                firstRoomDevil.Update(gameTime, player);
                if (currentScreen == screenWithBackgroundDevil) backgroundDevil.Update(gameTime);
                
                if (player.moving) // Enemies to only update while player is moving
                {
                    // Endless Follower
                    if (main.endless) follower.Update(gameTime, player, currentScreen);
                }
                // Reset Enemy Positions
                else
                {
                    follower.MovePositionBack();
                }

                player.SetRoom(this.roomLayout);
                player.Update(gameTime);
                player.SetSpeed(this.endless, currentScreen);

                // Set Music
                if (player.moving)
                {
                    if (MediaPlayer.Queue.ActiveSong == Music.main && MediaPlayer.State == MediaState.Stopped
                        || MediaPlayer.State != MediaState.Playing)
                    {
                        MediaPlayer.Play(Music.main);
                    }
                }

                // Set Bosses
                player.BossFight(this.devil);
                if (main.endless) player.Endless(this.follower);

                // Game Over
                if (player.gameOver)
                {
                    // Set Endless Mode Score
                    if (this.endless)
                    {
                        main.gameOver.SetEndlessScore(player.score);

                        main.title.SetHighscore();
                    }

                    // Go to Game Over Screen
                    SwitchState(main.gameOver);

                    // Reset Game Over Flag
                    player.gameOver = false;
                }

                // Update Particles
                foreach (HeatParticle heatParticle in heatParticles) heatParticle.Update(gameTime);

                // Timer Events
                heatParticleTimer += gameTime.ElapsedGameTime.Milliseconds;

                if (heatParticleTimer > timeBeforeNewHeatParticle)
                {
                    // Remove First Heat Particle
                    if (heatParticles.Count > heatParticleLimit) heatParticles.RemoveAt(0);

                    // Create New Heat Particle
                    GenerateHeat();

                    // Reset Timer
                    heatParticleTimer = 0f;
                }

                // Reset Room
                if (player.reachedEnd)
                {
                    // Randomize Room Layout
                    roomLayout.RandomizeRoom();

                    // Update Current Sceen Count
                    currentScreen++;

                    // Change Screen Color
                    if (screenColor.R > 70) screenColor = new Color(screenColor.R - 1, screenColor.G, screenColor.B);
                    if (screenColor.G < 140) screenColor = new Color(screenColor.R, screenColor.G + 1, screenColor.B);
                    if (screenColor.B < 220) screenColor = new Color(screenColor.R, screenColor.G, screenColor.B + 1);

                    // Hide Enemies
                    if (currentScreen != 0) firstRoomDevil.Hide();
                    if (main.endless) follower.MovePositionBack();

                    // Add to Score
                    player.score += random.Next(2, 5);

                    // Set Flag to False
                    player.reachedEnd = false;
                }

                // Regular Mode Content
                if (!endless)
                {
                    // Final Room Boss
                    if (currentScreen >= 99)
                    {
                        // Set Room Layout to Last Room
                        if (roomLayout.selectedRoomLayout != 9) roomLayout.GoToLastRoom();

                        // Put Player in Center of Screen
                        int middleOfRoom = ((Global.resWidth / 2) - (player.Width / 2));
                        if (player.X > middleOfRoom)
                        {
                            if (!player.slowingDown) player.X = middleOfRoom;
                            player.centered = true;
                        }

                        // Update Devil Boss
                        devil.Update(gameTime, player);

                        if (devil.defeated)
                        {
                            endOverlay.move = true;
                        }
                    }
                }
            }

            // While Paused
            hud.Update(gameTime, player, currentScreen, main);

            if (Global.paused)
            {
                // Quit to Title
                if (KeyPress(Keys.X)
                    || ButtonPress(Buttons.B))
                {
                    SwitchState(main.title);

                    MediaPlayer.Stop();
                }
            }
        }

        public override void OnDraw(SpriteBatch spriteBatch)
        {
            // Background
            graphicsDevice.Clear(screenColor);
            levelBackground.Draw(spriteBatch);

            if (!this.endless) if (currentScreen == screenWithBackgroundDevil) backgroundDevil.Draw(spriteBatch);
            firstRoomDevil.Draw(spriteBatch);

            // Level
            roomLayout.Draw(spriteBatch);
            player.Draw(spriteBatch);
            if (this.endless) follower.Draw(spriteBatch);
            if (currentScreen >= 99) devil.Draw(spriteBatch);

            // Particles
            foreach (HeatParticle heatParticle in heatParticles) heatParticle.Draw(spriteBatch);

            // HUD
            roomDisclaimer.Draw(spriteBatch);
            hud.Draw(spriteBatch);
            endOverlay.Draw(spriteBatch);
            pauseOverlay.Draw(spriteBatch);
        }
    }
}
