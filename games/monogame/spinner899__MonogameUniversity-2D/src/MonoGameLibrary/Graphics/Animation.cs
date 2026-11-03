using System;
using System.Collections.Generic;

namespace MonoGameLibrary.Graphics;

public class Animation
{

    /// <summary>
    /// The texture regions that make up the frames of this animation.
    /// The order of the regions within the collection are the order that the frames should be displayed in.
    /// </summary>
    public List<TextureRegion> Frames { get; set; }


    /// <summary>
    /// The amonut of time to delay between each frame before mocing to the next frame for this animation.
    /// </summary>
    public TimeSpan Delay { get; set; }

    /// <summary>
    /// Creates a new animation.
   /// </summary>
    public Animation()
    {
        Frames = new List<TextureRegion>();
        Delay = TimeSpan.FromMilliseconds(100);
    }


    public Animation(List<TextureRegion> frames, TimeSpan delay)
    {
        Frames = frames;
        Delay = delay;
    }
}
