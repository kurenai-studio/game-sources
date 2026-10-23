// ESCAPEAWAY!
// https://store.steampowered.com/app/5143520/ESCAPEAWAY/

// Created by Snowman64
// Developed from August 8, 2026 - August 21, 2026

// Made for BOSS BASH JAM 4
// https://itch.io/jam/boss-bash-jam-4

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Xml.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway.Source;
using Escapeaway.Source.States;

namespace Escapeaway
{
    public class MainGame : Game
    {
        private GraphicsDeviceManager graphics;
        private SpriteBatch spriteBatch;

        // Public Variables
        public static GameTime gameTime;
        public static GraphicsDeviceManager publicGraphics;
        public static GraphicsDevice publicGraphicsDevice;

        // Game State
        private Main game;

        // Window Size
        private int
            windowedWidth,
            windowedHeight;

        public MainGame()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
        }

        protected override void Initialize()
        {
            // Set Public Variables
            publicGraphics = this.graphics;
            publicGraphicsDevice = this.GraphicsDevice;

            // Set Window Properties
            this.Window.Title = Global.windowName;
            this.Window.AllowUserResizing = true;
            this.Window.ClientSizeChanged += WindowSizeChanged;

            this.windowedWidth = Global.displayWidth;
            this.windowedHeight = Global.displayHeight;

            base.Initialize();
        }

        /// <summary>
        /// Keeps the size of the window update, depending on fullscreen or windowed mode.
        /// </summary>
        public void UpdateFullscreen()
        {
            // Store Windowed Size
            if (!graphics.IsFullScreen)
            {
                this.windowedWidth = this.GraphicsDevice.Viewport.Width;
                this.windowedHeight = this.GraphicsDevice.Viewport.Height;
            }

            // Set Bool to False (so method only runs once)
            Global.fullscreenChanged = false;

            // Change Screen Size depending on Fullscreen Status
            if (Global.fullscreen) // Fullscreen Mode
            {
                // Set Window to Monitor Size
                graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;
                graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;

                // Apply Changes before Fullscreen Status is Set
                // NOTE: This is to prevent any lag when the window is set to fullscreen.
                graphics.ApplyChanges();
            }
            if (!Global.fullscreen) // Windowed Mode
            {
                // Set Window to Previous Windowed Size
                graphics.PreferredBackBufferWidth = this.windowedWidth;
                graphics.PreferredBackBufferHeight = this.windowedHeight;
            }

            // Update Fullscreen Mode for Window
            this.graphics.IsFullScreen = Global.fullscreen;

            // Apply Changes to Window
            graphics.ApplyChanges();
        }

        private void WindowSizeChanged(object sender, EventArgs e)
        {
            game.cam.SetDestRect();
        }

        private void SetWindowSize(int width, int height)
        {
            // Set Bool to False (so method only runs once)
            Global.fullscreenChanged = false;

            // Change Screen Size depending on Fullscreen Status
            if (Global.fullscreen) // Fullscreen Mode
            {
                // Set Window to Monitor Size
                graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;
                graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;

                // Apply Changes before Fullscreen Status is Set
                // NOTE: This is to prevent any lag when the window is set to fullscreen.
                graphics.ApplyChanges();
            }
            if (!Global.fullscreen) // Windowed Mode
            {
                // Set Window to Previous Windowed Size
                graphics.PreferredBackBufferWidth = this.windowedWidth;
                graphics.PreferredBackBufferHeight = this.windowedHeight;
            }

            // Update Fullscreen Mode for Window
            this.graphics.IsFullScreen = Global.fullscreen;

            if (!this.graphics.IsFullScreen)
            {
                // Set Window Size
                graphics.PreferredBackBufferWidth = width;
                graphics.PreferredBackBufferHeight = height;
            }

            graphics.ApplyChanges();

            game.cam.SetDestRect();
        }

        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);

            // Load Game Assets
            Global.LoadAssets(this.Content);

            // Load Settings.xml File
            if (File.Exists("C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/Options.xml"))
            {
                Debug.Print("Loading Options.xml.");

                // Load File
                XDocument optionsDoc = XDocument.Load("C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/Options.xml");

                // Set Settings to File Properties
                try
                {
                    Global.fullscreen = Convert.ToBoolean(optionsDoc.Descendants("Fullscreen").First().Value);
                    Global.highscore = Convert.ToInt32(optionsDoc.Descendants("Highscore").First().Value);
                    Global.endlessHighscore = Convert.ToInt32(optionsDoc.Descendants("EndlessHighscore").First().Value);
                }
                catch (Exception e)
                {
                    Debug.Print("A specific option could not be found!\n" + e); // Print Error Log

                    // Run New Settings File
                    CreateOptionsFile();
                }

                Debug.Print("Options.xml loaded!");
            }
            else // If Settings.xml does not exist
            {
                // Create Settings File
                CheckAndCreateOptionsFile();
            }

            // Set Game State
            game = new Main();

            // Set Window Size on Startup
            SetWindowSize(Global.displayWidth, Global.displayHeight);
        }

        private void CheckAndCreateOptionsFile()
        {
            // Write Error Log
            Debug.Print("Options.xml does not exist in the current directory. Creating a new file...");

            // --- Create Directory ---

            if (Directory.Exists("C:/Users/" + Environment.UserName + "/Documents/"))
            {
                if (Directory.Exists("C:/Users/" + Environment.UserName + "/Documents/My Games/"))
                {
                    if (Directory.Exists("C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/"))
                    {
                        Debug.Print("Directory has been found!"); //Write to console
                    }
                    else // If Game Directory does not exist
                    {
                        Directory.CreateDirectory("C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/"); //Create the directory
                        Debug.Print("Creating new directory for C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/"); //Write to console
                    }
                }
                else // If "My Games" does not exist
                {
                    Directory.CreateDirectory("C:/Users/" + Environment.UserName + "/Documents/My Games/"); //Create the directory
                    Debug.Print("Creating new directory for C:/Users/" + Environment.UserName + "/Documents/My Games/"); //Write to console
                }
            }
            else // If Documents does not exist
            {
                Directory.CreateDirectory("C:/Users/" + Environment.UserName + "/Documents/"); //Create the directory
                Debug.Print("Creating new directory for C:/Users/" + Environment.UserName + "/Documents/"); //Write to console
            }

            // If File Already Exists
            if (Directory.Exists("C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/"))
            {
                CreateOptionsFile();
            }
            else
            {
                CheckAndCreateOptionsFile();
            }
        }

        private void CreateOptionsFile()
        {
            // Create Settings.xml File
            var optionsDoc = new XDocument(new XElement("Settings",
                new XElement("Fullscreen", new XElement("Value", graphics.IsFullScreen)),
                new XElement("Highscore", new XElement("Value", Global.highscore)),
                new XElement("EndlessHighscore", new XElement("Value", Global.endlessHighscore))
                ));

            // Save File
            optionsDoc.Save("C:/Users/" + Environment.UserName + "/Documents/My Games/ESCAPEAWAY!/Options.xml", SaveOptions.None);

            Debug.Print("Created Options.xml.");
        }

        protected override void Update(GameTime mainGameTime)
        {
            // Quit Game
            if (Global.quit) Exit();

            // Update Global Variables
            Global.active = this.IsActive;
            gameTime = mainGameTime;

            // When Create Options Called
            if (Global.checkAndCreateOptions)
            {
                // Run Create Settings.xml File
                CheckAndCreateOptionsFile();

                // End Event
                Global.checkAndCreateOptions = false;
            }

            // Update Game
            game.Update(mainGameTime, game);

            // Update Fullscreen
            if (Global.fullscreenChanged) UpdateFullscreen();

            base.Update(mainGameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.Black);

            game.cam.Activate();

            spriteBatch.Begin(SpriteSortMode.Deferred,
                BlendState.AlphaBlend,
                SamplerState.PointClamp,
                DepthStencilState.None,
                RasterizerState.CullNone
            );
            game.Draw(spriteBatch);
            spriteBatch.End();

            game.cam.Draw(spriteBatch);

            base.Draw(gameTime);
        }
    }
}
