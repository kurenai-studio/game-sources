using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.IO;
using System.Xml;
using System.Xml.Linq;

namespace Snake.Core.Graphics
{
    public class TextureAtlas
    {
        /// <summary>
        /// The regions of the texture atlas.
        /// </summary>
        /// <returns>The regions of the texture atlas.</returns>
        private Dictionary<string, TextureRegion> _regions;

        /// <summary>
        /// The animations of the texture atlas.
        /// </summary>
        /// <returns>The animations of the texture atlas.</returns>
        private Dictionary<string, Animation> _animations;

        /// <summary>
        /// The texture of the texture atlas.
        /// </summary>
        /// <returns>The texture of the texture atlas.</returns>
        public Texture2D Texture { get; private set; }

        /// <summary>
        /// Initializes a new instance of the TextureAtlas class.
        /// </summary>
        /// <returns>A new instance of the TextureAtlas class.</returns>
        public TextureAtlas() 
        {
            // Set the regions and animations
            _regions = new Dictionary<string, TextureRegion>();
            _animations = new Dictionary<string, Animation>();
        }

        /// <summary>
        /// Initializes a new instance of the TextureAtlas class with a texture.
        /// </summary>
        /// <param name="texture">The texture of the texture atlas.</param>
        /// <returns>A new instance of the TextureAtlas class.</returns>
        public TextureAtlas(Texture2D texture) 
        {
            // Set the texture
            Texture = texture;

            // Set the regions and animations
            _regions = new Dictionary<string, TextureRegion>();
            _animations = new Dictionary<string, Animation>();
        }

        /// <summary>
        /// Adds a region to the texture atlas.
        /// </summary>
        /// <param name="name">The name of the region.</param>
        /// <param name="x">The x position of the region.</param>
        /// <param name="y">The y position of the region.</param>
        /// <param name="width">The width of the region.</param>
        /// <param name="height">The height of the region.</param>
        public void AddRegion(string name, int x, int y, int width, int height)
        {
            // Create a new region
            TextureRegion region = new TextureRegion(Texture, x, y, width, height);

            // Add the region to the regions dictionary
            _regions.Add(name, region);
        }

        /// <summary>
        /// Gets a region from the texture atlas.
        /// </summary>
        /// <param name="name">The name of the region.</param>
        /// <returns>The region.</returns>
        public TextureRegion GetRegion(string name) 
        {
            // Check if the region name is null or empty and throw an exception
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentException("Region name cannot be null or empty.", nameof(name));

            // Check if the region is in the regions dictionary and throw an exception if it is not
            if (!_regions.TryGetValue(name, out TextureRegion region))
                throw new KeyNotFoundException($"Region '{name}' not found in texture atlas.");

            // Return the region
            return region;
        }

        /// <summary>
        /// Removes a region from the texture atlas.
        /// </summary>
        /// <param name="name">The name of the region.</param>
        /// <returns>True if the region was removed, false otherwise.</returns>
        public bool RemoveRegion(string name)
        {
            // Remove the region from the regions dictionary and return true if it was removed, false otherwise
            return _regions.Remove(name);
        }

        /// <summary>
        /// Clears the texture atlas.
        /// </summary>
        public void Clear()
        {
            // Clear the regions dictionary
            _regions.Clear();
        }

        /// <summary>
        /// Creates a sprite from a region.
        /// </summary>
        /// <param name="regionName">The name of the region.</param>
        /// <returns>The sprite.</returns>
        public Sprite CreateSprite(string regionName)
        {
            // Get the region from the texture atlas
            TextureRegion region = GetRegion(regionName);

            // Create a new sprite
            return new Sprite(region);
        }

        /// <summary>
        /// Adds an animation to the texture atlas.
        /// </summary>
        /// <param name="animationName">The name of the animation.</param>
        /// <param name="animation">The animation.</param>
        public void AddAnimation(string animationName, Animation animation)
        {
            // Add the animation to the animations dictionary
            _animations[animationName] = animation;
        }

        /// <summary>
        /// Gets an animation from the texture atlas.
        /// </summary>
        /// <param name="animationName">The name of the animation.</param>
        /// <returns>The animation.</returns>
        public Animation GetAnimation(string animationName)
        {
            // Check if the animation name is null or empty and throw an exception
            if (string.IsNullOrWhiteSpace(animationName))
                throw new ArgumentException("Animation name cannot be null or empty.", nameof(animationName));

            // Check if the animation is in the animations dictionary and throw an exception if it is not
            if (!_animations.TryGetValue(animationName, out Animation animation))
                throw new KeyNotFoundException($"Animation '{animationName}' not found in texture atlas.");

            // Return the animation
            return animation;
        }

        /// <summary>
        /// Removes an animation from the texture atlas.
        /// </summary>
        /// <param name="animationName">The name of the animation.</param>
        /// <returns>True if the animation was removed, false otherwise.</returns>
        public bool RemoveAnimation(string animationName)
        {
            // Remove the animation from the animations dictionary and return true if it was removed, false otherwise
            return _animations.Remove(animationName);
        }

        /// <summary>
        /// Creates an animated sprite from an animation.
        /// </summary>
        /// <param name="animationName">The name of the animation.</param>
        /// <returns>The animated sprite.</returns>
        public AnimatedSprite CreateAnimatedSprite(string animationName)
        {
            // Get the animation from the texture atlas
            Animation animation = GetAnimation(animationName);

            // Create a new animated sprite
            return new AnimatedSprite(animation);
        }

        /// <summary>
        /// Creates a texture atlas from a XML file.
        /// </summary>
        /// <param name="content">The content manager.</param>
        /// <param name="filename">The filename of the XML file.</param>
        /// <returns>The texture atlas.</returns>
        public static TextureAtlas FromFile(ContentManager content, string filename)
        {
            // Create a new texture atlas
            TextureAtlas atlas = new TextureAtlas();

            // Get the file path
            string filePath = Path.Combine(content.RootDirectory, filename);

            // Open the stream
            using (Stream stream = TitleContainer.OpenStream(filePath))
            {
                using (XmlReader reader = XmlReader.Create(stream))
                {
                    // Load the document
                    XDocument document = XDocument.Load(reader);
                    XElement rootElement = document.Root;

                    // Get the texture path
                    string texturePath = rootElement.Element("Texture").Value;
                    atlas.Texture = content.Load<Texture2D>(texturePath);

                    // Get the region elements
                    var regionElements = rootElement.Element("Regions")?.Elements("Region");
                    if (regionElements != null)
                    {
                        // Loop through the region elements
                        foreach (var regionElement in regionElements)
                        {
                            string name = regionElement.Attribute("name").Value;
                            int x = int.Parse(regionElement.Attribute("x").Value);
                            int y = int.Parse(regionElement.Attribute("y").Value);
                            int width = int.Parse(regionElement.Attribute("width").Value);
                            int height = int.Parse(regionElement.Attribute("height").Value);

                            // Check if the name is not null or empty and add the region to the texture atlas
                            if (!string.IsNullOrWhiteSpace(name))
                            {
                                atlas.AddRegion(name, x, y, width, height);
                            }
                        }
                    }

                    // Get the animations element
                    var animationsElement = rootElement.Element("Animations");

                    // Get the animation elements
                    var animationElements = animationsElement?.Elements("Animation");
                    if (animationElements != null)
                    {
                        // Loop through the animation elements
                        foreach (var animationElement in animationElements)
                        {
                            string name = animationElement.Attribute("name").Value;
                            float delayValue = float.Parse(animationElement.Attribute("delay").Value);
                            TimeSpan delay = TimeSpan.FromMilliseconds(delayValue);

                            // Create a new list of texture regions
                            List<TextureRegion> frames = new List<TextureRegion>();

                            // Get the frame elements
                            var frameElements = animationElement.Elements("Frame");
                            if (frameElements != null) 
                            {
                                // Loop through the frame elements
                                foreach (var frameElement in frameElements)
                                {
                                    string regionName = frameElement.Attribute("region").Value;
                                    TextureRegion region = atlas.GetRegion(regionName);
                                    frames.Add(region);
                                }
                            }

                            // Add the animation to the texture atlas
                            atlas.AddAnimation(name, new Animation(frames, delay));
                        }
                    }
                }
            }

            // Return the texture atlas
            return atlas;
        }
    }
}
