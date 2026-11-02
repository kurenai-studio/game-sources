using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Entities;

namespace Breakout.Systems;

/// <summary>
/// Minimal diagnostics HUD (toggled with F3 in BreakoutGame). Every production game
/// grows one of these; having live numbers on screen beats guessing why the
/// game feels wrong. FPS is averaged over half-second windows because a
/// per-frame readout flickers too fast to read.
/// </summary>
public sealed class DebugOverlay
{
    private int _frames;
    private float _elapsed;
    private float _fps;

    /// <summary>Call once per Draw with the frame's elapsed seconds.</summary>
    public void CountFrame(float dt)
    {
        _frames++;
        _elapsed += dt;
        if (_elapsed >= 0.5f)
        {
            _fps = _frames / _elapsed;
            _frames = 0;
            _elapsed = 0f;
        }
    }

    public void Draw(SpriteBatch spriteBatch, SpriteFont font, GameSession session)
    {
        float topSpeed = 0f;
        foreach (Ball ball in session.Balls)
            topSpeed = MathF.Max(topSpeed, ball.Speed);

        // This string allocates per frame — acceptable here because the
        // overlay is a debug tool that is off by default. The HUD proper
        // caches its strings (see GameSession.DrawHud).
        string text = $"FPS {_fps:0}   BALLS {session.Balls.Count} @ {topSpeed:0} px/s   " +
                      $"PARTICLES {session.Particles.Count}   POWERUPS {session.PowerUps.Count}";
        spriteBatch.DrawShadowedText(font, text, new Vector2(12, Screen.Height - 26),
            Color.Lime * 0.9f, 0.6f);
    }
}
