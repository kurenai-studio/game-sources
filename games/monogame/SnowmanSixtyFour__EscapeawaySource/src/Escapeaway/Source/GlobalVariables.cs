using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Media;

namespace Escapeaway.Source
{
    internal class Global
    {
        // Debug Mode

        public static bool debug = false;

        // Properties

        public static bool quit = false;

        public static string windowName = "ESCAPEAWAY!";
        public static int
            resWidth = 256,
            resHeight = 224;

        public static int
            displayWidth = 768,
            displayHeight = 672;

        public static string gameVersion = "1.0.0";

        public static int
            highscore = 0,
            endlessHighscore = 0;

        // Bools not to be messed with (window properties)
        public static bool
            checkAndCreateOptions = false, // Create Settings

            // Active Window
            pauseWhenInactive = true,
            active = true,
            
            // Fullscreen
            fullscreen = false, fullscreenChanged = false;

        // Game

        public static bool paused = false;
        public static int maxScore = 9999999;

        // Assets

        public static Texture2D
            // Util
            noImg,

            // Title
            snowman64,
            logo, titleOverlay,

            // Gameplay
            clouds, heatBG, endOverlay,
            ground,

            devil,
            player,

            // Projectiles
            newFireball, newFireballParry,
            fireball, fireballParry,

            // Particles
            dustParticle, heatParticle;
        public static SpriteFont
            defaultFont;

        public static void LoadAssets(ContentManager Content)
        {
            // Images
            noImg = Content.Load<Texture2D>("Assets/Images/pixel");

            snowman64 = Content.Load<Texture2D>("Assets/Images/Title/snowman64Logo");
            logo = Content.Load<Texture2D>("Assets/Images/Title/logo");
            titleOverlay = Content.Load<Texture2D>("Assets/Images/Title/titleOverlay");

            clouds = Content.Load<Texture2D>("Assets/Images/Level/clouds");
            heatBG = Content.Load<Texture2D>("Assets/Images/Level/heatBG");

            endOverlay = Content.Load<Texture2D>("Assets/Images/Level/endOverlay");

            ground = Content.Load<Texture2D>("Assets/Images/Level/ground");

            devil = Content.Load<Texture2D>("Assets/Images/Level/devil");
            player = Content.Load<Texture2D>("Assets/Images/Level/player");

            newFireball = Content.Load<Texture2D>("Assets/Images/Level/newFireball");
            newFireballParry = Content.Load<Texture2D>("Assets/Images/Level/newFireballParry");
            fireball = Content.Load<Texture2D>("Assets/Images/Level/fireball");
            fireballParry = Content.Load<Texture2D>("Assets/Images/Level/fireballParry");

            dustParticle = Content.Load<Texture2D>("Assets/Images/Level/dust");
            heatParticle = Content.Load<Texture2D>("Assets/Images/Level/heat");

            // Fonts
            defaultFont = Content.Load<SpriteFont>("Assets/Fonts/retroFont");

            // Audio
            SFX.intro = Content.Load<SoundEffect>("Assets/Audio/introJingle");

            SFX.select = Content.Load<SoundEffect>("Assets/Audio/buttonSelect");

            SFX.jump = Content.Load<SoundEffect>("Assets/Audio/jump");
            SFX.footsteps = Content.Load<SoundEffect>("Assets/Audio/footsteps");
            SFX.slide = Content.Load<SoundEffect>("Assets/Audio/slide");
            SFX.skid = Content.Load<SoundEffect>("Assets/Audio/skid");

            SFX.projectile = Content.Load<SoundEffect>("Assets/Audio/projectile");

            Music.title = Content.Load<Song>("Assets/Audio/title");
            Music.main = Content.Load<Song>("Assets/Audio/mainloop");
        }
    }

    internal class CustomColor
    {
        public static Color
            DarkRed = new Color(136, 20, 0),
            Red = new Color(168, 0, 32),
            Pink = new Color(248, 164, 192),
            LightOrange = new Color(248, 120, 88),
            Yellow = new Color(248, 184, 0),
            DarkAqua = new Color(0, 136, 136),
            Brown = new Color(80, 48, 0),
            Black = new Color(8, 8, 8),
            White = new Color(248, 248, 248);
    }

    internal class SFX
    {
        public static SoundEffect
            // Intro
            intro,

            // Menus
            select,

            // Level
            jump,
            footsteps,
            slide,
            skid,

            projectile;
    }

    internal class Music
    {
        public static Song
            // UIs
            title,

            // Gameplay
            main;
    }
}
