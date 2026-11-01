namespace DerelictDimension.ECS.Drawing;

public record struct AnimatedSpriteComponent : IComponent
{
    /// <summary>
    /// An array of frames in order, for example [1,2,2,3,2].
    /// </summary>
    public int[] Frames;
    /// <summary>
    /// Current frame in <see cref="Frames"/>.
    /// </summary>
    public int FrameNumber;
    /// <summary>
    /// Time since last frame switch.
    /// </summary>
    public float FrameRemainder;
    /// <summary>
    /// Time (in seconds) between frames.
    /// </summary>
    public float TimeBetweenFrames = 1f;

    public float EffectiveTimeBetweenFrames => TimeBetweenFrames / AnimationSpeedMultiplier;

    /// <summary>
    /// Use when gameplay effects are affecting <see cref="TimeBetweenFrames"/>.
    /// </summary>
    public float AnimationSpeedMultiplier = 1;

    public string BaseTexturePath;
    public bool InvalidateTexture = true;

    public AnimatedSpriteComponent() { }

    public AnimatedSpriteComponent(string baseTexturePath, int[] frames, float timeBetweenFrames = 1f)
    {
        BaseTexturePath = baseTexturePath;
        Frames = frames;
        TimeBetweenFrames = timeBetweenFrames;
    }

    public void Reset()
    {
        FrameNumber = 0;
        FrameRemainder = 0;
        InvalidateTexture = true;
    }
}
