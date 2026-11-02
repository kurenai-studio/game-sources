using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// Short interstitial between levels: banner, beat, then the next board loads
/// and play hands back to Ready. The actual loading happens here on timeout —
/// PlayingState only decides *that* the level is over, never what comes next;
/// keeping the transition work inside the transition state is what lets the
/// win check stay one line.
/// </summary>
public sealed class LevelClearedState : GameState
{
    private const float Duration = 2.0f;

    private float _timer;
    private string _banner; // built once in Enter — Draw runs 60x a second

    public LevelClearedState(GameStateManager manager) : base(manager) { }

    public override bool IsSimulation => true; // timer ticks count, like LifeLostState

    public override void Enter()
    {
        _banner = $"LEVEL {Session.LevelIndex + 1} CLEARED";
        AudioBank.LevelClear?.Play();
    }

    public override void Update(float dt, InputHelper input)
    {
        _timer += dt;
        if (_timer >= Duration)
        {
            Session.AdvanceLevel();
            // CreateServeState rather than new ReadyState() — today only the
            // modern modes have levels, but every back-to-the-serve transition
            // routing through the one mode switch point is what keeps that an
            // implementation detail instead of a trap.
            Manager.ChangeState(Manager.CreateServeState());
        }
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        DrawWorldAndHud(spriteBatch);

        spriteBatch.DrawRect(new Rectangle(0, 0, Screen.Width, Screen.Height),
            Color.Black * 0.35f);
        spriteBatch.DrawCenteredText(Font, _banner,
            new Vector2(Screen.Width / 2f, Screen.Height / 2f - 20), Color.Gold, 1.5f);
        spriteBatch.DrawCenteredText(Font, "GET READY",
            new Vector2(Screen.Width / 2f, Screen.Height / 2f + 30),
            new Color(150, 150, 165), 0.75f);
    }
}
