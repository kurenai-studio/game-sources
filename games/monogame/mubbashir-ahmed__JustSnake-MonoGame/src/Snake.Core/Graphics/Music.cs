using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Media;
using System;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Manages audio playback for both background music (Song) and sound effects (SoundEffect).
    /// </summary>
    public class Music<T>
    {
        /// <summary>
        /// The content path to the audio file.
        /// </summary>
        private readonly string contentPath;

        /// <summary>
        /// Whether the audio should repeat (only applies to Song).
        /// </summary>
        private readonly bool isRepeating;

        /// <summary>
        /// The sound effect instance (only used for SoundEffect).
        /// </summary>
        private SoundEffectInstance soundEffectInstance;

        /// <summary>
        /// Gets or sets the loaded audio (Song or SoundEffect).
        /// </summary>
        public T Audio { get; set; }

        /// <summary>
        /// Initializes a new instance of the Music class.
        /// </summary>
        /// <param name="contentPath">The content path to the audio file.</param>
        /// <param name="isRepeating">Whether the audio should repeat.</param>
        public Music(string contentPath, bool isRepeating = false) 
        {
            ArgumentNullException.ThrowIfNull(contentPath);

            // Set the content path and repeating flag
            this.contentPath = contentPath;
            this.isRepeating = isRepeating;
        } 

        /// <summary>
        /// Loads the audio content.
        /// </summary>
        /// <param name="contentManager">The content manager to load from.</param>
        public void LoadContent(ContentManager contentManager)
        {
            ArgumentNullException.ThrowIfNull(contentManager);

            // Load the audio
            Audio = contentManager.Load<T>(contentPath);

            // Handle Song-specific setup
            if (Audio is Song song)
            {
                MediaPlayer.IsRepeating = isRepeating;
            }
            // Handle SoundEffect-specific setup
            else if (Audio is SoundEffect soundEffect)
            {
                soundEffectInstance = soundEffect.CreateInstance();
                if (isRepeating)
                {
                    soundEffectInstance.IsLooped = true;
                }
            }
        }

        /// <summary>
        /// Plays the audio if it's loaded.
        /// </summary>
        public void Play()
        {
            if (Audio == null) return;

            // Handle Song playback
            if (Audio is Song song)
            {
                if (MediaPlayer.State != MediaState.Playing)
                {
                    MediaPlayer.Play(song);
                }
            }
            // Handle SoundEffect playback
            else if (Audio is SoundEffect soundEffect)
            {
                if (soundEffectInstance != null)
                {
                    if (soundEffectInstance.State != SoundState.Playing)
                    {
                        soundEffectInstance.Play();
                    }
                }
                else
                {
                    // Fallback: play directly if instance creation failed
                    soundEffect.Play();
                }
            }
        }

        /// <summary>
        /// Stops the currently playing audio.
        /// </summary>
        public void Stop()
        {
            // Handle Song stop
            if (Audio is Song)
            {
                if (MediaPlayer.State == MediaState.Playing)
                {
                    MediaPlayer.Stop();
                }
            }
            // Handle SoundEffect stop
            else if (Audio is SoundEffect)
            {
                if (soundEffectInstance != null && soundEffectInstance.State == SoundState.Playing)
                {
                    soundEffectInstance.Stop();
                }
            }
        }
    }
}
