using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>Ball glued to the paddle, waiting for the launch input.</summary>
public sealed class ReadyState : GameState
{
    public ReadyState(GameStateManager manager) : base(manager) { }

    public override bool IsSimulation => true;

    public override void Enter() => Session.ResetForServe();

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Pause))
        {
            Manager.ChangeState(new PauseState(Manager, this));
            return;
        }

        foreach (Paddle paddle in Session.Paddles)
            paddle.Update(dt, input);
        Session.Balls[0].Update(dt); // ResetForServe guarantees exactly one

        if (input.WasActionJustPressed(GameAction.Launch) || input.WasLeftClickJustPressed)
        {
            Session.Balls[0].Launch(Session.Rng);
            Manager.ChangeState(new PlayingState(Manager));
        }
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        DrawWorldAndHud(spriteBatch);

        // A translucent strip behind the prompts. The shadow pass keeps text
        // legible over a stray brick; the strip is for *composition* — it
        // groups the prompt block and reads as UI, not as part of the board.
        spriteBatch.DrawRect(new Rectangle(0, 282, Screen.Width, 66),
            Color.Black * 0.45f);

        spriteBatch.DrawCenteredText(Font, "PRESS SPACE OR CLICK TO LAUNCH",
            new Vector2(Screen.Width / 2f, 300), Color.White);
        string hint = Session.Mode == GameMode.Coop
            ? "P1 LEFT HALF: MOUSE / A-D    P2 RIGHT HALF: ARROWS / GAMEPAD"
            : "MOVE: MOUSE / ARROWS / A-D / GAMEPAD";
        spriteBatch.DrawCenteredText(Font, hint,
            new Vector2(Screen.Width / 2f, 332), new Color(150, 150, 165), 0.75f);
    }
}
