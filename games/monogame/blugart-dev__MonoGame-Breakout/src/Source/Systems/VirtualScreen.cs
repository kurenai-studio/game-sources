using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Breakout.Systems;

/// <summary>
/// Virtual-resolution rendering: the whole game draws into an off-screen
/// RenderTarget2D at a fixed 800x480, which is then scaled onto the real
/// back buffer with aspect-ratio-preserving letterboxing. Gameplay code can
/// assume one resolution forever; the window can be anything.
///
/// This is the piece every shipping MonoGame project has — full engines bundle
/// it as a "stretch mode" or "resolution scaling" project setting. Here you
/// build it yourself, and in exchange you see all the moving parts: the render
/// target, the destination rectangle math, and why mouse coordinates must be
/// transformed back (the OS reports them in *window* pixels, but the game
/// thinks in *virtual* pixels).
/// </summary>
public sealed class VirtualScreen
{
    private readonly GraphicsDevice _device;
    private readonly RenderTarget2D _target;

    public int VirtualWidth { get; }
    public int VirtualHeight { get; }

    /// <summary>
    /// "Pixel perfect" mode. At a fractional scale (say 1.4x) some virtual
    /// pixels come out 1 window pixel wide and some 2 — and as things move,
    /// *which* pixels get the extra column changes every frame. That crawling
    /// is the "shimmer" pixel-art games suffer. Flooring the scale to a whole
    /// number makes every virtual pixel exactly the same size, trading bigger
    /// letterbox bars for perfectly stable pixels. This is why pixel-art games
    /// ship an integer-scaling toggle instead of just always doing it: at
    /// 1080p an 800x480 game floors to 2x = 1600x960, leaving thick bars some
    /// players hate more than shimmer. Let the player pick.
    /// </summary>
    public bool IntegerScaling { get; set; }

    /// <summary>CRT look on the final present (scanlines, curvature). On by
    /// default — it sells the arcade fantasy — and toggleable, because every
    /// post-process that changes the whole image must be the player's choice.</summary>
    public bool CrtEnabled { get; set; } = true;

    private Effect _crtEffect;

    /// <summary>
    /// Hand over the compiled CRT shader (loaded by the shell — only it has
    /// the ContentManager). The tuning constants are set once here: Effect
    /// parameters persist on the object, so per-frame Present calls don't
    /// re-send what never changes.
    /// </summary>
    public void SetCrtEffect(Effect effect)
    {
        _crtEffect = effect;
        effect.Parameters["VirtualSize"].SetValue(new Vector2(VirtualWidth, VirtualHeight));
        effect.Parameters["Curvature"].SetValue(0.08f);
        // Gentle on purpose: at the default window size the game presents at
        // exactly 1x, where the scanline period is a single physical pixel —
        // any stronger and the effect reads as a dark comb over the image
        // instead of a memory of phosphor rows.
        effect.Parameters["ScanlineStrength"].SetValue(0.09f);
        effect.Parameters["VignetteStrength"].SetValue(0.14f);
    }

    public VirtualScreen(GraphicsDevice device, int virtualWidth, int virtualHeight)
    {
        _device = device;
        VirtualWidth = virtualWidth;
        VirtualHeight = virtualHeight;
        _target = new RenderTarget2D(device, virtualWidth, virtualHeight);
    }

    /// <summary>
    /// Where the virtual image lands on the back buffer: scaled by the
    /// smaller of the two axis ratios (so it always fits) and centered
    /// (the leftover area becomes the black letterbox bars).
    /// </summary>
    public Rectangle DestinationBounds
    {
        get
        {
            int windowWidth = _device.PresentationParameters.BackBufferWidth;
            int windowHeight = _device.PresentationParameters.BackBufferHeight;

            float scale = MathF.Min(
                (float)windowWidth / VirtualWidth,
                (float)windowHeight / VirtualHeight);

            // Only floor when the result stays >= 1x — in a window smaller
            // than the virtual resolution there is no integer scale to snap
            // to, so fall back to plain fit-and-letterbox.
            if (IntegerScaling && scale >= 1f)
                scale = MathF.Floor(scale);

            int width = (int)(VirtualWidth * scale);
            int height = (int)(VirtualHeight * scale);
            return new Rectangle(
                (windowWidth - width) / 2, (windowHeight - height) / 2, width, height);
        }
    }

    /// <summary>All drawing after this call lands in the virtual target.</summary>
    public void BeginDraw() => _device.SetRenderTarget(_target);

    /// <summary>
    /// Switch back to the real back buffer and draw the virtual image onto it,
    /// scaled. PointClamp keeps the scale-up crisp instead of bilinear-smeared.
    /// This single Draw is where a post-process slots in: the whole game is
    /// one texture by now, so one Effect on this call shades every pixel of
    /// the frame — the cheapest full-screen pass there is.
    /// </summary>
    public void Present(SpriteBatch spriteBatch)
    {
        _device.SetRenderTarget(null); // null = the actual back buffer
        _device.Clear(Color.Black);    // letterbox bar color

        spriteBatch.Begin(samplerState: SamplerState.PointClamp,
            effect: CrtEnabled ? _crtEffect : null); // null = SpriteBatch default
        spriteBatch.Draw(_target, DestinationBounds, Color.White);
        spriteBatch.End();
    }

    /// <summary>Window-client pixels -> virtual pixels (inverse of the present scale).</summary>
    public Point WindowToVirtual(Point windowPosition)
    {
        Rectangle dest = DestinationBounds;
        if (dest.Width == 0 || dest.Height == 0)
            return windowPosition; // minimized window; avoid dividing by zero

        float scale = (float)VirtualWidth / dest.Width;
        return new Point(
            (int)((windowPosition.X - dest.X) * scale),
            (int)((windowPosition.Y - dest.Y) * scale));
    }
}
