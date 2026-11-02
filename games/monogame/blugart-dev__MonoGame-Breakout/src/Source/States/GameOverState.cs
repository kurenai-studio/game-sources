using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>End screen for both outcomes; Enter or click starts a fresh run.</summary>
public sealed class GameOverState : GameState
{
    private readonly bool _won;
    private int _rank; // 0-based place in the top five, -1 if unplaced

    public GameOverState(GameStateManager manager, bool won) : base(manager)
        => _won = won;

    public override void Enter()
    {
        // Submit once, on entry — Enter() is the state machine's natural
        // "this just happened" hook, and Update would re-submit every tick.
        // Unless this is a replay ending: the run already scored when it was
        // played live, and a recording must never bank its points twice.
        _rank = Manager.IsPlayingBack ? -1 : HighScores.Record(Session.ScoreTable, Session.Score);

        // Duck the music so the verdict jingle owns the moment.
        MusicPlayer.SetDucked(true);
        if (_won)
            AudioBank.Win?.Play();
        else
            AudioBank.LifeLost?.Play();
    }

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Restart) || input.WasLeftClickJustPressed)
        {
            MusicPlayer.SetDucked(false);
            Manager.RestartCurrentGame();
        }
        else if (input.WasActionJustPressed(GameAction.TitleScreen))
        {
            MusicPlayer.SetDucked(false);
            Manager.GoToTitle();
        }
        else if (Manager.LastReplay != null
            && input.WasActionJustPressed(GameAction.WatchReplay))
        {
            MusicPlayer.SetDucked(false);
            Manager.StartPlayback();
        }
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        DrawWorldAndHud(spriteBatch);

        // Dim the frozen world so the text owns the screen. `Color * 0.65f`
        // premultiplies, which is what SpriteBatch's default blend expects.
        spriteBatch.DrawRect(new Rectangle(0, 0, Screen.Width, Screen.Height),
            Color.Black * 0.65f);

        var center = new Vector2(Screen.Width / 2f, 140);
        spriteBatch.DrawCenteredText(Font, _won ? "YOU WIN!" : "GAME OVER",
            center, _won ? Color.Gold : Color.OrangeRed, 2f);
        spriteBatch.DrawCenteredText(Font, $"FINAL SCORE  {Session.Score}",
            center + new Vector2(0, 56), Color.White);
        if (_rank == 0)
            spriteBatch.DrawCenteredText(Font, "NEW HIGH SCORE!",
                center + new Vector2(0, 92), Color.Gold, 0.9f);

        // The mode's top five, with this run's entry picked out in gold.
        IReadOnlyList<int> top = HighScores.For(Session.ScoreTable);
        for (int i = 0; i < top.Count; i++)
            spriteBatch.DrawCenteredText(Font, $"{i + 1}.  {top[i]}",
                center + new Vector2(0, 130 + i * 28),
                i == _rank ? Color.Gold : new Color(150, 150, 165), 0.75f);

        spriteBatch.DrawCenteredText(Font, "PRESS ENTER OR CLICK TO PLAY AGAIN",
            center + new Vector2(0, 290), new Color(150, 150, 165), 0.75f);
        string exits = Manager.LastReplay != null
            ? "T FOR TITLE SCREEN   R TO WATCH REPLAY"
            : "T FOR TITLE SCREEN";
        spriteBatch.DrawCenteredText(Font, exits,
            center + new Vector2(0, 318), new Color(150, 150, 165), 0.75f);
    }
}
