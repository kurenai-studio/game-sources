// The main state of the game.

using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway.Source;
using Escapeaway.Source.States;
using Microsoft.Xna.Framework.Media;

namespace Escapeaway.Source.States
{
    internal class Main : State
    {
        // Current State of Game
        public State currentState;

        // Game States
        public IntroState intro;
        public TitleState title;
        public OptionsState options;
        public StoryState story;
        public CreditsState credits;
        public LevelState level;
        public WinState win;
        public GameOverState gameOver;

        // Endless Mode
        public bool endless = false;

        public Main()
        {
            // Initialize States
            intro = new IntroState();
            title = new TitleState();
            options = new OptionsState();
            story = new StoryState();
            credits = new CreditsState();
            level = new LevelState();
            win = new WinState();
            gameOver = new GameOverState();

            // Set Current State
            currentState = intro;
        }

        public override void OnUpdate(GameTime gameTime, Main main)
        {
            // Pausing
            if (canPause) // If Pausing is Possible
            {
                // When Escape is Pressed
                if (KeyPress(Keys.Escape))
                {
                    // If the State should quit game
                    if (currentState == title)
                    {
                        // Quit Game
                        Global.quit = true;
                    }
                }
                if (KeyPress(Keys.Escape)
                    || ButtonPress(Buttons.Start))
                {
                    // If the State is capable of pausing (gameplay)
                    if (currentState == level)
                    {
                        // Toggle Pause
                        Global.paused = !Global.paused;
                    }
                }
            }
            
            // Unpause when not in Level
            if (Global.paused && currentState != level) Global.paused = false;

            // Pause Game when Inactive
            if (Global.pauseWhenInactive && !Global.active) Global.paused = true;

            // Kill Music
            if (currentState == gameOver
                || currentState == win)
            {
                if (MediaPlayer.State == MediaState.Playing) MediaPlayer.Stop();
            }

            // Update Current State
            currentState.Update(gameTime, this);
        }

        public override void OnDraw(SpriteBatch spriteBatch)
        {
            // Draw Current State
            currentState.OnDraw(spriteBatch);
        }
    }
}
