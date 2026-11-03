#:package MonoGame.Framework.DesktopGL@3.8.5.1

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

internal static class Essentials
{
    #region Game Constants
    public const int ScreenWidth = 800;
    public const int ScreenHeight = 600;
    public const int CellSize = 20;
    public const int GridCols = ScreenWidth / CellSize;
    public const int GridRows = ScreenHeight / CellSize;
    #endregion

    #region Tiny Font (4x5) Utility
    private const int TinyFontScale = 2;
    private const int TinyFontSpacing = 1;
    private const int TinyFontGlyphW = 4;
    private const int TinyFontGlyphH = 5;
    private static readonly Dictionary<char, byte[]> TinyFont = new()
    {
        ['A'] = [0b0110, 0b1001, 0b1111, 0b1001, 0b1001],
        ['B'] = [0b1110, 0b1001, 0b1110, 0b1001, 0b1110],
        ['C'] = [0b0110, 0b1001, 0b1000, 0b1000, 0b0111],
        ['D'] = [0b1110, 0b1001, 0b1001, 0b1001, 0b1110],
        ['E'] = [0b1111, 0b1000, 0b1110, 0b1000, 0b1111],
        ['F'] = [0b1111, 0b1000, 0b1110, 0b1000, 0b1000],
        ['G'] = [0b0111, 0b1000, 0b1011, 0b1001, 0b0111],
        ['H'] = [0b1001, 0b1001, 0b1111, 0b1001, 0b1001],
        ['I'] = [0b1110, 0b0100, 0b0100, 0b0100, 0b1110],
        ['J'] = [0b0011, 0b0001, 0b0001, 0b1001, 0b0110],
        ['K'] = [0b1001, 0b1010, 0b1100, 0b1010, 0b1001],
        ['L'] = [0b1000, 0b1000, 0b1000, 0b1000, 0b1111],
        ['M'] = [0b1001, 0b1111, 0b1111, 0b1001, 0b1001],
        ['N'] = [0b1001, 0b1101, 0b1011, 0b1001, 0b1001],
        ['O'] = [0b0110, 0b1001, 0b1001, 0b1001, 0b0110],
        ['P'] = [0b1110, 0b1001, 0b1110, 0b1000, 0b1000],
        ['Q'] = [0b0110, 0b1001, 0b1001, 0b1011, 0b0111],
        ['R'] = [0b1110, 0b1001, 0b1110, 0b1010, 0b1001],
        ['S'] = [0b0111, 0b1000, 0b0110, 0b0001, 0b1110],
        ['T'] = [0b1111, 0b0010, 0b0010, 0b0010, 0b0010],
        ['U'] = [0b1001, 0b1001, 0b1001, 0b1001, 0b0110],
        ['V'] = [0b1001, 0b1001, 0b1001, 0b1010, 0b1100],
        ['W'] = [0b1001, 0b1001, 0b1111, 0b1111, 0b1001],
        ['X'] = [0b1001, 0b0110, 0b0110, 0b0110, 0b1001],
        ['Y'] = [0b1001, 0b0101, 0b0010, 0b0010, 0b0010],
        ['Z'] = [0b1111, 0b0001, 0b0110, 0b1000, 0b1111],
        ['0'] = [0b0110, 0b1001, 0b1011, 0b1101, 0b0110],
        ['1'] = [0b0010, 0b0110, 0b0010, 0b0010, 0b0111],
        ['2'] = [0b1110, 0b0001, 0b0010, 0b1100, 0b1111],
        ['3'] = [0b1110, 0b0001, 0b0110, 0b0001, 0b1110],
        ['4'] = [0b1010, 0b1010, 0b1111, 0b0010, 0b0010],
        ['5'] = [0b1110, 0b1000, 0b1110, 0b0001, 0b1110],
        ['6'] = [0b0110, 0b1000, 0b1110, 0b1001, 0b0110],
        ['7'] = [0b1111, 0b1001, 0b0010, 0b0100, 0b0100],
        ['8'] = [0b0110, 0b1001, 0b0110, 0b1001, 0b0110],
        ['9'] = [0b0110, 0b1001, 0b0111, 0b0001, 0b0001],
        ['.'] = [0b0000, 0b0000, 0b0000, 0b0010, 0b0000],
        ['!'] = [0b0110, 0b0110, 0b0010, 0b0000, 0b0010],
        ['-'] = [0b0000, 0b0000, 0b0111, 0b0000, 0b0000],
        [':'] = [0b0000, 0b0010, 0b0000, 0b0010, 0b0000],
        ['@'] = [0b0110, 0b1011, 0b1011, 0b1000, 0b0111],
        ['#'] = [0b0101, 0b1111, 0b0101, 0b1111, 0b0101],
        ['\''] = [0b0100, 0b0100, 0b0000, 0b0000, 0b0000],
        ['"'] = [0b1010, 0b1010, 0b0000, 0b0000, 0b0000],
        [','] = [0b0000, 0b0000, 0b0000, 0b0010, 0b0100],
        [' '] = [0b0000, 0b0000, 0b0000, 0b0000, 0b0000],
    };
    #endregion

    #region Extension Methods
    extension(GraphicsDevice graphicsDevice)
    {
        public Texture2D CreatePixelTexture()
        {
            Texture2D pixel = new(graphicsDevice, 1, 1);
            pixel.SetData([Color.White]);
            return pixel;
        }
    }

    extension(SpriteBatch batch)
    {
        public void DrawTinyText(Texture2D? pixel, string text, Vector2 position, Color color)
        {
            ArgumentNullException.ThrowIfNull(pixel);
            float posX = position.X;
            foreach (char c in text.ToUpperInvariant())
            {
                if (TinyFont.TryGetValue(c, out byte[]? pxRows))
                {
                    ArgumentNullException.ThrowIfNull(pxRows);
                    for (int row = 0; row < TinyFontGlyphH; row++)
                    {
                        byte bits = pxRows[row];
                        for (int col = 0; col < TinyFontGlyphW; col++)
                        {
                            bool px = (bits & (1 << (TinyFontGlyphW - 1 - col))) != 0;
                            if (!px) continue;

                            batch.Draw(pixel, new Rectangle(
                                (int)(posX + col * TinyFontScale),
                                (int)(position.Y + row * TinyFontScale),
                                TinyFontScale, TinyFontScale),
                                color);
                        }
                    }
                }
                posX += (TinyFontGlyphW + TinyFontSpacing) * TinyFontScale;
            }
        }

        public void DrawCell(Texture2D pixel, Point cell, Color color, int inset)
        {
            batch.Draw(pixel, new Rectangle(
                cell.X * CellSize + inset,
                cell.Y * CellSize + inset,
                CellSize - inset * 2,
                CellSize - inset * 2), color);
        }

        public void DrawCentered(Texture2D pixel, string text, float yOffset, Color color)
        {
            const int GlyphAdvance = 2 * (TinyFontGlyphW + TinyFontSpacing);
            float width = text.Length * GlyphAdvance - 2;
            float x = (ScreenWidth - width) / 2f;
            float y = (ScreenHeight - 10) / 2f + yOffset;
            batch.DrawTinyText(pixel, text, new Vector2(x, y), color);
        }
    }
    #endregion
}

internal sealed class SnakeGame : Game
{
    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch? _spriteBatch;
    private Texture2D? _pixel;

    // Snake state
    private readonly LinkedList<Point> _snake = new();
    private Point _food;
    private Point _direction;
    private Point _pendingDirection;
    private double _moveTimer;
    private double _moveInterval = 0.15;
    private const double MinMoveInterval = 0.06;
    private const double SpeedUpPerFood = 0.004;

    private int _score;
    private int _highScore;
    private bool _gameOver;
    private bool _gameStarted;

    // Pause state
    private bool _paused;
    private KeyboardState _prevKeyboard;

    private readonly Random _random = new();

    public SnakeGame()
    {
        _graphics = new GraphicsDeviceManager(this);
        IsMouseVisible = false;
        Window.Title = "C# File-Based Snake Game";
    }

    protected override void Initialize()
    {
        _graphics.PreferredBackBufferWidth = Essentials.ScreenWidth;
        _graphics.PreferredBackBufferHeight = Essentials.ScreenHeight;
        _graphics.ApplyChanges();
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _pixel = GraphicsDevice.CreatePixelTexture();
        StartNewGame();
    }

    private void StartNewGame()
    {
        _snake.Clear();
        int cx = Essentials.GridCols / 2;
        int cy = Essentials.GridRows / 2;
        for (int i = 0; i < 5; i++)
            _snake.AddLast(new Point(cx - i, cy));

        _direction = new Point(1, 0);
        _pendingDirection = _direction;
        _moveTimer = 0;
        _moveInterval = 0.15;
        _score = 0;
        _gameOver = false;
        _gameStarted = false;
        _paused = false;
        SpawnFood();
    }

    private void SpawnFood()
    {
        var occupied = new HashSet<Point>(_snake);
        var free = new List<Point>(Essentials.GridCols * Essentials.GridRows);
        for (int y = 0; y < Essentials.GridRows; y++)
            for (int x = 0; x < Essentials.GridCols; x++)
            {
                var p = new Point(x, y);
                if (!occupied.Contains(p)) free.Add(p);
            }

        if (free.Count == 0)
        {
            _gameOver = true;
            return;
        }
        _food = free[_random.Next(free.Count)];
    }

    protected override void Update(GameTime gameTime)
    {
        var keyboard = Keyboard.GetState();
        var gamepad = GamePad.GetState(PlayerIndex.One);

        // Edge-detect just-pressed keys
        bool pressedP = keyboard.IsKeyDown(Keys.P) && _prevKeyboard.IsKeyUp(Keys.P);
        bool pressedEscape = keyboard.IsKeyDown(Keys.Escape) && _prevKeyboard.IsKeyUp(Keys.Escape);
        bool pressedR = keyboard.IsKeyDown(Keys.R) && _prevKeyboard.IsKeyUp(Keys.R);
        bool pressedSpace = keyboard.IsKeyDown(Keys.Space) && _prevKeyboard.IsKeyUp(Keys.Space);

        // Global quit using Escape
        if (pressedEscape)
        {
            Exit();
            base.Update(gameTime);
            return;
        }

        if (_gameOver)
        {
            if (pressedR || pressedSpace)
                StartNewGame();
            _prevKeyboard = keyboard;
            base.Update(gameTime);
            return;
        }

        // Toggle pause with P, but only while the game has started
        if (_gameStarted && (pressedP || pressedSpace))
            _paused = !_paused;

        // While paused, swallow everything else
        if (_paused)
        {
            _prevKeyboard = keyboard;
            base.Update(gameTime);
            return;
        }

        HandleInput(keyboard);

        if (!_gameStarted)
        {
            // Use just-pressed direction keys to start
            if (keyboard.IsKeyDown(Keys.Up) || keyboard.IsKeyDown(Keys.W) ||
                keyboard.IsKeyDown(Keys.Down) || keyboard.IsKeyDown(Keys.S) ||
                keyboard.IsKeyDown(Keys.Left) || keyboard.IsKeyDown(Keys.A) ||
                keyboard.IsKeyDown(Keys.Right) || keyboard.IsKeyDown(Keys.D))
                _gameStarted = true;
        }

        if (_gameStarted)
        {
            _moveTimer += gameTime.ElapsedGameTime.TotalSeconds;
            while (_moveTimer >= _moveInterval)
            {
                _moveTimer -= _moveInterval;
                StepSnake();
                if (_gameOver) break;
            }
        }

        _prevKeyboard = keyboard;
        _score = Math.Clamp(_score, 0, 999);
        _highScore = Math.Clamp(_highScore, 0, 999);

        base.Update(gameTime);
    }

    private void HandleInput(KeyboardState keyboard)
    {
        Point desired = _pendingDirection;

        if (keyboard.IsKeyDown(Keys.Up) || keyboard.IsKeyDown(Keys.W))
            desired = new Point(0, -1);
        else if (keyboard.IsKeyDown(Keys.Down) || keyboard.IsKeyDown(Keys.S))
            desired = new Point(0, 1);
        else if (keyboard.IsKeyDown(Keys.Left) || keyboard.IsKeyDown(Keys.A))
            desired = new Point(-1, 0);
        else if (keyboard.IsKeyDown(Keys.Right) || keyboard.IsKeyDown(Keys.D))
            desired = new Point(1, 0);

        if (desired.X == -_direction.X && desired.Y == -_direction.Y)
            return;
        if (desired.X == -_pendingDirection.X && desired.Y == -_pendingDirection.Y)
            return;

        _pendingDirection = desired;
    }

    private void StepSnake()
    {
        _direction = _pendingDirection;
        Point head = _snake.First!.Value;
        Point newHead = new(head.X + _direction.X, head.Y + _direction.Y);

        if (newHead.X < 0 || newHead.X >= Essentials.GridCols ||
            newHead.Y < 0 || newHead.Y >= Essentials.GridRows)
        {
            _gameOver = true;
            _highScore = Math.Max(_highScore, _score);
            return;
        }

        bool eating = newHead == _food;
        var tail = _snake.Last!.Value;
        bool hitsSelf = _snake.Contains(newHead) && !(!eating && newHead == tail);
        if (hitsSelf)
        {
            _gameOver = true;
            _highScore = Math.Max(_highScore, _score);
            return;
        }

        _snake.AddFirst(newHead);

        if (eating)
        {
            _score++;
            _highScore = Math.Max(_highScore, _score);
            _moveInterval = Math.Max(MinMoveInterval, _moveInterval - SpeedUpPerFood);
            SpawnFood();
        }
        else
        {
            _snake.RemoveLast();
        }
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(new Color(18, 18, 24));

        if (_spriteBatch is SpriteBatch batch && _pixel is Texture2D pixel)
        {
            batch.Begin(samplerState: SamplerState.PointClamp);

            Color gridColor = new(30, 30, 40);
            for (int x = 0; x <= Essentials.GridCols; x++)
                batch.Draw(pixel, new Rectangle(
                    x * Essentials.CellSize, 0, 1, Essentials.ScreenHeight), gridColor);
            for (int y = 0; y <= Essentials.GridRows; y++)
                batch.Draw(pixel, new Rectangle(
                    0, y * Essentials.CellSize, Essentials.ScreenWidth, 1), gridColor);

            batch.DrawCell(pixel, _food, new Color(230, 70, 90), inset: 2);

            bool first = true;
            foreach (var seg in _snake)
            {
                Color color = first ? new(150, 240, 150) : new(70, 190, 90);
                batch.DrawCell(pixel, seg, color, inset: 1);
                first = false;
            }

            Vector2 highScoreTextPos = new(Essentials.ScreenWidth - 100, 8);
            batch.DrawTinyText(pixel, $"SCORE: {_score,3}", new Vector2(8, 8), Color.MintCream);
            batch.DrawTinyText(pixel, $"BEST: {_highScore,3}", highScoreTextPos, Color.MintCream);

            if (!_gameStarted && !_gameOver)
            {
                batch.DrawCentered(pixel, "C# FILE-BASED SNAKE GAME", -75, Color.Yellow);
                batch.DrawCentered(pixel, "USE ARROWS OR \"WASD\" TO MOVE THE SNAKE,", -35, Color.White);
                batch.DrawCentered(pixel, "PRESS \"P\" OR SPACE TO PAUSE, AND ESC TO QUIT", -15, Color.White);
                batch.DrawCentered(pixel, "MOVE THE SNAKE TO BEGIN THE GAME", 50, new Color(70, 190, 90));
            }

            if (_gameOver)
            {
                batch.DrawCentered(pixel, "G A M E   O V E R", -30, new Color(255, 120, 120));
                batch.DrawCentered(pixel, $"FINAL SCORE: {_score}", -10, Color.White);
                batch.DrawCentered(pixel, "PRESS \"R\" OR SPACE TO RESTART", 20, new Color(200, 200, 200));
            }

            // Pause overlay goes last so it covers everything beneath it
            if (_paused)
            {
                // Dim the playfield
                batch.Draw(pixel, new Rectangle(0, 0, Essentials.ScreenWidth, Essentials.ScreenHeight),
                    new Color(0, 0, 0, 160));

                batch.DrawCentered(pixel, "PAUSED", -20, Color.White);
                batch.DrawCentered(pixel, "PRESS \"P\" OR SPACE TO RESUME", 10, new Color(200, 200, 200));
            }

            batch.End();
        }

        base.Draw(gameTime);
    }

    private static void Main()
    {
        using SnakeGame game = new();
        game.Run();
    }
}