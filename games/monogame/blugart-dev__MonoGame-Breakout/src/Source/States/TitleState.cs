using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// The menu before anything exists. Every other state operates on a running
/// GameSession; this one's job is to *create* it — which flushed out the
/// hidden assumption that "the game has already started" (the manager now
/// builds a placeholder session at boot just so the shell has a Shake matrix
/// to read). Selecting an entry calls StartNewGame with a mode and, for the
/// modern game, a starting level — the session parameter the level-select
/// exercise was designed to force.
/// </summary>
public sealed class TitleState : GameState
{
    private const int ModernEntry = 0;
    private const int CoopEntry = 1;
    private const int ClassicEntry = 2;
    private const int DoubleEntry = 3;
    private const int CavityEntry = 4;
    private const int ProgressiveEntry = 5;
    private const int EntryCount = 6;

    private static readonly Color DimColor = new(150, 150, 165);

    private int _selected;
    private int _startLevel; // modern/co-op only; 0-based like Session.LevelIndex

    public TitleState(GameStateManager manager) : base(manager) { }

    public override void Update(float dt, InputHelper input)
    {
        // Two entries means up and down both "go to the other one", but the
        // modulo form is written for N — adding a mode is one constant.
        if (input.WasActionJustPressed(GameAction.MenuUp))
            _selected = (_selected + EntryCount - 1) % EntryCount;
        if (input.WasActionJustPressed(GameAction.MenuDown))
            _selected = (_selected + 1) % EntryCount;

        // Left/right reuse the move actions — on a menu they read as "adjust".
        // Modern and co-op share the level boards, so both get level select;
        // the arcade modes' walls are fixed by their manuals.
        // One slot past the real levels selects endless generated boards —
        // the sentinel GameSession.IsProcedural reads. The clamp's upper bound
        // is LevelCount itself, not LevelCount - 1, to include that slot.
        bool hasLevelSelect = _selected is ModernEntry or CoopEntry;
        if (hasLevelSelect)
        {
            if (input.WasActionJustPressed(GameAction.MoveLeft))
                _startLevel = MathHelper.Clamp(_startLevel - 1, 0, GameSession.LevelCount);
            if (input.WasActionJustPressed(GameAction.MoveRight))
                _startLevel = MathHelper.Clamp(_startLevel + 1, 0, GameSession.LevelCount);
        }

        if (input.WasActionJustPressed(GameAction.Launch)
            || input.WasActionJustPressed(GameAction.Restart)
            || input.WasLeftClickJustPressed)
        {
            Manager.StartNewGame(SelectedMode, hasLevelSelect ? _startLevel : 0);
        }
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        var center = new Vector2(Screen.Width / 2f, 0);

        spriteBatch.DrawCenteredText(Font, "BREAKOUT",
            center + new Vector2(0, 120), Color.Gold, 3f);

        // A nod to the 1976 cabinet: its colors were cellophane strips over a
        // black-and-white monitor, so the title wears the same four bands.
        DrawColorBands(spriteBatch);

        string level = _startLevel == GameSession.LevelCount
            ? "< RANDOM >"
            : $"< LEVEL {_startLevel + 1} >";
        DrawEntry(spriteBatch, $"MODERN GAME    {level}", 240, _selected == ModernEntry);
        DrawEntry(spriteBatch, $"CO-OP  2P      {level}", 270, _selected == CoopEntry);
        DrawEntry(spriteBatch, "CLASSIC 1976", 300, _selected == ClassicEntry);
        DrawEntry(spriteBatch, "SUPER 1978  DOUBLE", 330, _selected == DoubleEntry);
        DrawEntry(spriteBatch, "SUPER 1978  CAVITY", 360, _selected == CavityEntry);
        DrawEntry(spriteBatch, "SUPER 1978  PROGRESSIVE", 390, _selected == ProgressiveEntry);

        // The highlighted mode's record, straight from the JSON save file.
        // The RANDOM slot competes in its own table.
        bool randomSelected = _selected is ModernEntry or CoopEntry
            && _startLevel == GameSession.LevelCount;
        int best = HighScores.Best(GameSession.ScoreTableFor(SelectedMode, randomSelected));
        if (best > 0)
            spriteBatch.DrawCenteredText(Font, $"BEST  {best}",
                center + new Vector2(0, 418), Color.Gold, 0.75f);

        spriteBatch.DrawCenteredText(Font,
            "UP/DOWN SELECT   LEFT/RIGHT START LEVEL   SPACE PLAY",
            center + new Vector2(0, 442), DimColor, 0.7f);
        spriteBatch.DrawCenteredText(Font,
            "P PAUSE   M MUSIC   F9 CRT   F10 PIXEL-PERFECT   F11 FULLSCREEN   ESC QUIT",
            center + new Vector2(0, 462), DimColor, 0.7f);
    }

    private GameMode SelectedMode => _selected switch
    {
        CoopEntry => GameMode.Coop,
        ClassicEntry => GameMode.Classic,
        DoubleEntry => GameMode.SuperDouble,
        CavityEntry => GameMode.SuperCavity,
        ProgressiveEntry => GameMode.SuperProgressive,
        _ => GameMode.Modern,
    };

    private void DrawEntry(SpriteBatch spriteBatch, string text, int y, bool selected)
    {
        spriteBatch.DrawCenteredText(Font, selected ? $"> {text} <" : text,
            new Vector2(Screen.Width / 2f, y),
            selected ? Color.White : DimColor,
            selected ? 1f : 0.85f);
    }

    private static void DrawColorBands(SpriteBatch spriteBatch)
    {
        Color[] bands =
        {
            new(255, 77, 77), new(255, 138, 48), new(87, 212, 118), new(255, 205, 66),
        };
        for (int i = 0; i < bands.Length; i++)
            spriteBatch.DrawRect(
                new Rectangle(Screen.Width / 2 - 140, 170 + i * 10, 280, 8), bands[i]);
    }
}
