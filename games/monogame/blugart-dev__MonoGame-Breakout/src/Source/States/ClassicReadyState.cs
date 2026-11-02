using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// Waiting for a classic serve. The 1976 serve is nothing like the modern
/// launch: there is no ball riding the paddle and no aiming. You press serve
/// and the ball *materializes* mid-screen already moving — toward you, at the
/// slowest of the four speeds, on a random angle. The machine served at the
/// player; the player's job started at the first paddle contact.
/// </summary>
public sealed class ClassicReadyState : GameState
{
    public ClassicReadyState(GameStateManager manager) : base(manager) { }

    public override bool IsSimulation => true;

    public override void Enter() => Session.PrepareClassicServe();

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Pause))
        {
            Manager.ChangeState(new PauseState(Manager, this));
            return;
        }

        Session.Paddles[0].Update(dt, input);

        if (input.WasActionJustPressed(GameAction.Launch) || input.WasLeftClickJustPressed)
            Serve();
    }

    private void Serve()
    {
        var ball = Session.Balls[0]; // PrepareClassicServe guarantees exactly one

        // "About midway along the TV screen" (manual) — see ServePosition.
        ball.Position = ClassicRules.ServePosition(Session.Rng);

        ball.OverrideSpeed(ClassicRules.Speeds[0]); // every serve restarts the speed ladder
        ball.Velocity = ClassicRules.ServeDirection(Session.Rng) * ball.Speed;

        Manager.ChangeState(new ClassicPlayingState(Manager));
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        DrawWorldAndHud(spriteBatch);

        // Same prompt strip as the modern ready screen — see ReadyState.Draw.
        spriteBatch.DrawRect(new Rectangle(0, 282, Screen.Width, 124),
            Color.Black * 0.45f);

        spriteBatch.DrawCenteredText(Font, "PRESS SPACE OR CLICK TO SERVE",
            new Vector2(Screen.Width / 2f, 300), Color.White);

        // The original cabinet displayed the ball number — serves count up,
        // not down, so "BALL 2" means your second serve, not two remaining.
        int ballNumber = GameSession.StartingLives - Session.Lives + 1;
        spriteBatch.DrawCenteredText(Font,
            $"BALL {ballNumber} OF {GameSession.StartingLives}",
            new Vector2(Screen.Width / 2f, 332), new Color(150, 150, 165), 0.75f);

        // The cabinet put its rules on the bezel card; the serve screen is
        // ours. One line for the law a player cannot infer from watching.
        spriteBatch.DrawCenteredText(Font,
            "ONE BRICK PER TRIP - THE BALL RE-ARMS AT THE PADDLE OR BACKWALL",
            new Vector2(Screen.Width / 2f, 362), new Color(150, 150, 165), 0.7f);

        spriteBatch.DrawCenteredText(Font, "MOVE: MOUSE / ARROWS / A-D / GAMEPAD",
            new Vector2(Screen.Width / 2f, 390), new Color(150, 150, 165), 0.75f);
    }
}
