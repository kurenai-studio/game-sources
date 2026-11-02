using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// Pause as a state, not a flag. The naive route is `if (_paused) return;`
/// sprinkled through Update — this is the same idea expressed once: while
/// this object is current, nothing else receives Update, so the world cannot
/// move. The state it interrupted is kept and swapped back on resume, which
/// is why pausing works identically from Ready and from Playing without
/// either of them knowing how to "re-enter" themselves mid-flight.
/// </summary>
public sealed class PauseState : GameState
{
    private readonly GameState _resumeTo;

    public PauseState(GameStateManager manager, GameState resumeTo) : base(manager)
        => _resumeTo = resumeTo;

    // Freeze particles and shake too: a paused screen with embers still
    // falling reads as "broken", not "paused". This is the design question
    // hiding in UpdateEffects — pause is the one state that wants the world
    // *and* its garnish stopped.
    public override bool FreezesEffects => true;

    // The world freezes but the music only dims: a quiet track still playing
    // says "paused"; total silence says "hung". Unducking lives here too —
    // resume bypasses Enter() by design, so the interrupted state never knows
    // the volume changed.
    public override void Enter() => MusicPlayer.SetDucked(true);

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Pause))
        {
            MusicPlayer.SetDucked(false);
            Manager.ResumeState(_resumeTo);
        }
        else if (input.WasActionJustPressed(GameAction.OpenRebind))
        {
            // Music stays ducked: the rebind screen is part of being paused.
            Manager.ChangeState(new RebindState(Manager, this, input.Actions));
        }
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        // The interrupted state keeps drawing the world exactly as it left it;
        // we only dim it and put the label on top.
        _resumeTo.Draw(spriteBatch);

        spriteBatch.DrawRect(new Rectangle(0, 0, Screen.Width, Screen.Height),
            Color.Black * 0.55f);
        spriteBatch.DrawCenteredText(Font, "PAUSED",
            new Vector2(Screen.Width / 2f, Screen.Height / 2f - 20), Color.White, 1.5f);
        spriteBatch.DrawCenteredText(Font, "PRESS P TO RESUME",
            new Vector2(Screen.Width / 2f, Screen.Height / 2f + 30),
            new Color(150, 150, 165), 0.75f);
        spriteBatch.DrawCenteredText(Font, "B REBIND KEYS",
            new Vector2(Screen.Width / 2f, Screen.Height / 2f + 60),
            new Color(150, 150, 165), 0.75f);
    }
}
