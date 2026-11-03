using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input.Touch;
using Snake.Core.Enums;
using Snake.Core.Inputs;
using Snake.Core.Managers;
using System;
using System.Runtime;

namespace Snake.Core.Screens
{
    /// <summary>
    /// Base class for all game screens.
    /// </summary>
    public abstract class GameScreen
    {
        /// <summary>
        /// The transition alpha base.
        /// </summary>
        private const float TransitionAlphaBase = 1f;

        /// <summary>
        /// The transition clamp min.
        /// </summary>
        private const float TransitionClampMin = 0f;

        /// <summary>
        /// The transition clamp max.
        /// </summary>
        private const float TransitionClampMax = 1f;

        /// <summary>
        /// Whether this screen is a popup.
        /// </summary>
        private bool isPopup;

        /// <summary>
        /// The transition on time.
        /// </summary>
        private TimeSpan transitionOnTime = TimeSpan.Zero;

        /// <summary>
        /// The transition off time.
        /// </summary>
        private TimeSpan transitionOffTime = TimeSpan.Zero;

        /// <summary>
        /// The transition position.
        /// </summary>
        private float transitionPosition = 1;

        /// <summary>
        /// The current screen state.
        /// </summary>
        private ScreenState screenState = ScreenState.TransitionOn;

        /// <summary>
        /// Whether this screen is exiting.
        /// </summary>
        private bool isExiting;

        /// <summary>
        /// Whether another screen has focus.
        /// </summary>
        private bool otherScreenHasFocus;

        /// <summary>
        /// The screen manager.
        /// </summary>
        private ScreenManager screenManager;

        /// <summary>
        /// The controlling player.
        /// </summary>
        private PlayerIndex? controllingPlayer;

        /// <summary>
        /// The enabled gestures.
        /// </summary>
        private GestureType enabledGestures = GestureType.None;

        /// <summary>
        /// The transition x offset on.
        /// </summary>
        private float transitionXOffsetOn = 256f;

        /// <summary>
        /// The transition x offset off.
        /// </summary>
        private float transitionXOffsetOff = 512f;

        /// <summary>
        /// The default transition time.
        /// </summary>
        private double defaultTransitionTime = 0.2;

        /// <summary>
        /// The transition offset multiplier.
        /// </summary>
        private float transitionOffsetMultiplier = 100f;

        /// <summary>
        /// The fade alpha multiplier.
        /// </summary>
        private float fadeAlphaMultiplier = 2f / 3f;

        /// <summary>
        /// The title scale.
        /// </summary>
        private float titleScale = 2.8f;

        /// <summary>
        /// The title position y offset.
        /// </summary>
        private float titlePositionYOffset = 200f;

        /// <summary>
        /// Gets or sets whether this screen is a popup.
        /// </summary>
        public bool IsPopup
        {
            get => isPopup;
            protected set => isPopup = value;
        }

        /// <summary>
        /// Gets or sets the transition on time.
        /// </summary>
        public TimeSpan TransitionOnTime
        {
            get => transitionOnTime;
            protected set => transitionOnTime = value;
        }

        /// <summary>
        /// Gets or sets the transition off time.
        /// </summary>
        public TimeSpan TransitionOffTime
        {
            get => transitionOffTime;
            protected set => transitionOffTime = value;
        }

        /// <summary>
        /// Gets or sets the transition x offset on.
        /// </summary>
        public float TransitionXOffsetOn
        {
            get => transitionXOffsetOn;
            private set => transitionXOffsetOn = value;
        }

        /// <summary>
        /// Gets or sets the transition x offset off.
        /// </summary>
        public float TransitionXOffsetOff
        {
            get => transitionXOffsetOff;
            private set => transitionXOffsetOff = value;
        }

        /// <summary>
        /// Gets or sets the default transition time.
        /// </summary>
        public double DefaultTransitionTime
        {
            get => defaultTransitionTime;
            private set => defaultTransitionTime = value;
        }

        /// <summary>
        /// Gets or sets the transition position (0-1).
        /// </summary>
        public float TransitionPosition
        {
            get => transitionPosition;
            protected set => transitionPosition = value;
        }

        /// <summary>
        /// Gets or sets the transition offset multiplier.
        /// </summary>
        public float TransitionOffsetMultiplier
        {
            get => transitionOffsetMultiplier;
            private set => transitionOffsetMultiplier = value;
        }

        /// <summary>
        /// Gets the transition alpha value.
        /// </summary>
        public float TransitionAlpha => TransitionAlphaBase - TransitionPosition;

        /// <summary>
        /// Gets or sets the fade alpha multiplier.
        /// </summary>
        public float FadeAlphaMultiplier
        {
            get => fadeAlphaMultiplier;
            private set => fadeAlphaMultiplier = value;
        }

        /// <summary>
        /// Gets or sets the title scale.
        /// </summary>
        public float TitleScale
        {
            get => titleScale;
            private set => titleScale = value;
        }

        /// <summary>
        /// Gets or sets the title position y offset.
        /// </summary>
        public float TitlePositionYOffset
        {
            get => titlePositionYOffset;
            private set => titlePositionYOffset = value;
        }

        /// <summary>
        /// Gets or sets the current screen state.
        /// </summary>
        public ScreenState ScreenState
        {
            get => screenState;
            protected set => screenState = value;
        }

        /// <summary>
        /// Gets or sets whether the screen is exiting.
        /// </summary>
        public bool IsExiting
        {
            get => isExiting;
            protected internal set => isExiting = value;
        }

        /// <summary>
        /// Gets whether the screen is currently active.
        /// </summary>
        public bool IsActive => !otherScreenHasFocus &&
                                (screenState == ScreenState.TransitionOn ||
                                 screenState == ScreenState.Active);

        /// <summary>
        /// Gets or sets the screen manager.
        /// </summary>
        public ScreenManager ScreenManager
        {
            get => screenManager;
            internal set => screenManager = value;
        }

        /// <summary>
        /// Gets or sets the controlling player.
        /// </summary>
        public PlayerIndex? ControllingPlayer
        {
            get => controllingPlayer;
            internal set => controllingPlayer = value;
        }

        /// <summary>
        /// Gets or sets the enabled gestures.
        /// </summary>
        public GestureType EnabledGestures
        {
            get => enabledGestures;
            protected set
            {
                enabledGestures = value;

                if (ScreenState == ScreenState.Active)
                {
                    TouchPanel.EnabledGestures = value;
                }
            }
        }

        /// <summary>
        /// Loads screen content.
        /// </summary>
        public virtual void LoadContent()
        {
            ScreenManager?.ScalePresentationArea();
        }

        /// <summary>
        /// Unloads screen content.
        /// </summary>
        public virtual void UnloadContent() { }

        /// <summary>
        /// Updates the screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="otherScreenHasFocus">Whether another screen has focus.</param>
        /// <param name="coveredByOtherScreen">Whether this screen is covered by another screen.</param>
        public virtual void Update(GameTime gameTime, bool otherScreenHasFocus, bool coveredByOtherScreen)
        {
            this.otherScreenHasFocus = otherScreenHasFocus;

            if (isExiting)
            {
                screenState = ScreenState.TransitionOff;

                if (!UpdateTransition(gameTime, transitionOffTime, 1))
                {
                    ScreenManager?.RemoveScreen(this);
                }
            }
            else if (coveredByOtherScreen)
            {
                if (UpdateTransition(gameTime, transitionOffTime, 1))
                {
                    screenState = ScreenState.TransitionOff;
                }
                else
                {
                    screenState = ScreenState.Hidden;
                }
            }
            else
            {
                if (UpdateTransition(gameTime, transitionOnTime, -1))
                {
                    screenState = ScreenState.TransitionOn;
                }
                else
                {
                    screenState = ScreenState.Active;
                }
            }

            // Check if backbuffer size changed and rescale if needed
            if (ScreenManager != null)
            {
                var graphicsDevice = ScreenManager.GraphicsDevice;
                if (graphicsDevice != null &&
                    (ScreenManager.BackbufferHeight != graphicsDevice.PresentationParameters.BackBufferHeight ||
                     ScreenManager.BackbufferWidth != graphicsDevice.PresentationParameters.BackBufferWidth))
                {
                    ScreenManager.ScalePresentationArea();
                }
            }
        }

        /// <summary>
        /// Updates the transition state.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="time">The transition time.</param>
        /// <param name="direction">The transition direction (1 for off, -1 for on).</param>
        /// <returns>True if transition is still in progress, false if complete.</returns>
        private bool UpdateTransition(GameTime gameTime, TimeSpan time, int direction)
        {
            float transitionDelta = time == TimeSpan.Zero
                ? 1f
                : (float)(gameTime.ElapsedGameTime.TotalMilliseconds / time.TotalMilliseconds);

            transitionPosition += transitionDelta * direction;

            if ((direction < 0 && transitionPosition <= TransitionClampMin) ||
                (direction > 0 && transitionPosition >= TransitionClampMax))
            {
                transitionPosition = MathHelper.Clamp(transitionPosition, TransitionClampMin, TransitionClampMax);
                return false;
            }

            return true;
        }

        /// <summary>
        /// Handles input for the screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="inputState">The input state.</param>
        public virtual void HandleInput(GameTime gameTime, InputState inputState) { }

        /// <summary>
        /// Draws the screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public virtual void Draw(GameTime gameTime) { }

        /// <summary>
        /// Exits the screen.
        /// </summary>
        public void ExitScreen()
        {
            if (TransitionOffTime == TimeSpan.Zero)
            {
                ScreenManager?.RemoveScreen(this);
            }
            else
            {
                isExiting = true;
            }
        }
    }
}
