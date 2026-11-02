using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// Short frozen beat after losing the ball, then back to Ready. The pause is
/// deliberate game feel: it marks the failure before play resumes.
/// </summary>
public sealed class LifeLostState : GameState
{
    private const float Duration = 1.4f;

    private float _timer;

    public LifeLostState(GameStateManager manager) : base(manager) { }

    // Part of the run's timeline even though it reads no input: its ticks
    // *count* (the timer), so record and playback must both spend them.
    public override bool IsSimulation => true;

    public override void Enter()
    {
        Session.Shake.Add(0.6f);
        AudioBank.LifeLost?.Play();
    }

    public override void Update(float dt, InputHelper input)
    {
        _timer += dt;
        if (_timer >= Duration)
            Manager.ChangeState(Manager.CreateServeState()); // mode decides which Ready
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        DrawWorldAndHud(spriteBatch);

        // Every banner state dims the world it interrupts (LevelCleared 0.35,
        // Pause 0.55, GameOver 0.65) — this one used to skip it, and the
        // flash got lost against a busy board. Lightest of the family: the
        // world should still read as "right there", only marked.
        spriteBatch.DrawRect(new Rectangle(0, 0, Screen.Width, Screen.Height),
            Color.Black * 0.35f);

        // Hard on/off flash at 2 Hz — steps read more "arcade" than a smooth fade.
        if ((int)(_timer * 4f) % 2 == 0)
            spriteBatch.DrawCenteredText(Font, "LIFE LOST",
                new Vector2(Screen.Width / 2f, Screen.Height / 2f),
                Color.OrangeRed, 1.5f);
    }
}
