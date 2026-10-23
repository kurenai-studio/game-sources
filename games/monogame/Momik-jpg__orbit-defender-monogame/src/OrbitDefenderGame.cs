using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using OrbitDefender.Core;
using OrbitDefender.Models;
using OrbitDefender.Services;

namespace OrbitDefender;

public sealed class OrbitDefenderGame : Game
{
    private static readonly IReadOnlyDictionary<char, string[]> PixelFont = new Dictionary<char, string[]>
    {
        ['A'] = new[] { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
        ['B'] = new[] { "11110", "10001", "10001", "11110", "10001", "10001", "11110" },
        ['C'] = new[] { "01110", "10001", "10000", "10000", "10000", "10001", "01110" },
        ['D'] = new[] { "11110", "10001", "10001", "10001", "10001", "10001", "11110" },
        ['E'] = new[] { "11111", "10000", "10000", "11110", "10000", "10000", "11111" },
        ['F'] = new[] { "11111", "10000", "10000", "11110", "10000", "10000", "10000" },
        ['G'] = new[] { "01110", "10001", "10000", "10111", "10001", "10001", "01110" },
        ['H'] = new[] { "10001", "10001", "10001", "11111", "10001", "10001", "10001" },
        ['I'] = new[] { "11111", "00100", "00100", "00100", "00100", "00100", "11111" },
        ['J'] = new[] { "00111", "00010", "00010", "00010", "10010", "10010", "01100" },
        ['K'] = new[] { "10001", "10010", "10100", "11000", "10100", "10010", "10001" },
        ['L'] = new[] { "10000", "10000", "10000", "10000", "10000", "10000", "11111" },
        ['M'] = new[] { "10001", "11011", "10101", "10101", "10001", "10001", "10001" },
        ['N'] = new[] { "10001", "11001", "10101", "10011", "10001", "10001", "10001" },
        ['O'] = new[] { "01110", "10001", "10001", "10001", "10001", "10001", "01110" },
        ['P'] = new[] { "11110", "10001", "10001", "11110", "10000", "10000", "10000" },
        ['Q'] = new[] { "01110", "10001", "10001", "10001", "10101", "10010", "01101" },
        ['R'] = new[] { "11110", "10001", "10001", "11110", "10100", "10010", "10001" },
        ['S'] = new[] { "01111", "10000", "10000", "01110", "00001", "00001", "11110" },
        ['T'] = new[] { "11111", "00100", "00100", "00100", "00100", "00100", "00100" },
        ['U'] = new[] { "10001", "10001", "10001", "10001", "10001", "10001", "01110" },
        ['V'] = new[] { "10001", "10001", "10001", "10001", "10001", "01010", "00100" },
        ['W'] = new[] { "10001", "10001", "10001", "10101", "10101", "10101", "01010" },
        ['X'] = new[] { "10001", "10001", "01010", "00100", "01010", "10001", "10001" },
        ['Y'] = new[] { "10001", "10001", "01010", "00100", "00100", "00100", "00100" },
        ['Z'] = new[] { "11111", "00001", "00010", "00100", "01000", "10000", "11111" },
        ['0'] = new[] { "01110", "10001", "10011", "10101", "11001", "10001", "01110" },
        ['1'] = new[] { "00100", "01100", "00100", "00100", "00100", "00100", "01110" },
        ['2'] = new[] { "01110", "10001", "00001", "00010", "00100", "01000", "11111" },
        ['3'] = new[] { "11110", "00001", "00001", "01110", "00001", "00001", "11110" },
        ['4'] = new[] { "00010", "00110", "01010", "10010", "11111", "00010", "00010" },
        ['5'] = new[] { "11111", "10000", "10000", "11110", "00001", "00001", "11110" },
        ['6'] = new[] { "01110", "10000", "10000", "11110", "10001", "10001", "01110" },
        ['7'] = new[] { "11111", "00001", "00010", "00100", "01000", "01000", "01000" },
        ['8'] = new[] { "01110", "10001", "10001", "01110", "10001", "10001", "01110" },
        ['9'] = new[] { "01110", "10001", "10001", "01111", "00001", "00001", "01110" },
        [' '] = new[] { "00000", "00000", "00000", "00000", "00000", "00000", "00000" },
        [':'] = new[] { "00000", "00100", "00000", "00000", "00100", "00000", "00000" },
        ['.'] = new[] { "00000", "00000", "00000", "00000", "00000", "00100", "00100" },
        ['-'] = new[] { "00000", "00000", "00000", "11111", "00000", "00000", "00000" },
        ['|'] = new[] { "00100", "00100", "00100", "00100", "00100", "00100", "00100" },
        ['('] = new[] { "00010", "00100", "01000", "01000", "01000", "00100", "00010" },
        [')'] = new[] { "01000", "00100", "00010", "00010", "00010", "00100", "01000" },
        ['/'] = new[] { "00001", "00010", "00100", "01000", "10000", "00000", "00000" },
        ['?'] = new[] { "01110", "10001", "00001", "00010", "00100", "00000", "00100" }
    };

    private readonly GraphicsDeviceManager _graphics;
    private readonly IInputService _inputService;
    private readonly ISpawnService _spawnService;
    private readonly ICollisionService _collisionService;
    private readonly IHighScoreService _highScoreService;

    private readonly List<LaserShot> _shots = new();
    private readonly List<Asteroid> _asteroids = new();
    private readonly List<Star> _stars = new();
    private readonly List<HighScoreEntry> _highScores = new();

    private SpriteBatch? _spriteBatch;
    private Texture2D? _pixel;

    private GameSession _session = new();
    private PlayerShip _player = null!;
    private GameMode _mode = GameMode.Menu;
    private double _spawnTimerSeconds;
    private bool _scoreRecorded;
    private string _statusMessage = "DRUECKE ENTER START";
    private string _pilotName = GameSettings.DefaultPilotName;
    private KeyboardState _previousKeyboardState;

    private const int MaxPilotNameLength = 12;

    public OrbitDefenderGame()
    {
        _graphics = new GraphicsDeviceManager(this);
        _graphics.PreferredBackBufferWidth = GameSettings.WindowWidth;
        _graphics.PreferredBackBufferHeight = GameSettings.WindowHeight;
        _graphics.SynchronizeWithVerticalRetrace = true;

        IsFixedTimeStep = true;
        IsMouseVisible = true;
        Window.AllowUserResizing = true;
        Window.Title = "Orbit Defender - Andrin Portfolio";

        _inputService = new InputService();
        _spawnService = new SpawnService();
        _collisionService = new CollisionService();
        _highScoreService = new HighScoreService();
    }

    protected override void Initialize()
    {
        StartMenuState();
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _pixel = new Texture2D(GraphicsDevice, 1, 1);
        _pixel.SetData(new[] { Color.White });

        _spawnService.PopulateStars(_stars, GetPlayBounds());
        RefreshHighScores();
    }

    protected override void Update(GameTime gameTime)
    {
        _inputService.Update();
        var keyboardState = Keyboard.GetState();

        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed)
        {
            Exit();
            return;
        }

        var deltaSeconds = (float)gameTime.ElapsedGameTime.TotalSeconds;
        var playBounds = GetPlayBounds();

        UpdateStars(deltaSeconds, playBounds);

        switch (_mode)
        {
            case GameMode.Menu:
                HandlePilotNameInput(keyboardState);
                if (_inputService.IsStartPressed)
                {
                    StartNewRun(playBounds);
                }

                break;
            case GameMode.Playing:
                if (_inputService.IsPausePressed)
                {
                    _mode = GameMode.Paused;
                    _statusMessage = "PAUSE ENTER ODER P FORTSETZEN";
                    break;
                }

                UpdatePlaying(deltaSeconds, playBounds);
                break;
            case GameMode.Paused:
                if (_inputService.IsPausePressed || _inputService.IsStartPressed)
                {
                    _mode = GameMode.Playing;
                    _statusMessage = "RUN FORTGESETZT";
                }

                break;
            case GameMode.GameOver:
                HandlePilotNameInput(keyboardState);
                if (_inputService.IsRestartPressed)
                {
                    StartNewRun(playBounds);
                }
                else if (_inputService.IsBackPressed)
                {
                    StartMenuState();
                }

                break;
        }

        _previousKeyboardState = keyboardState;
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        if (_spriteBatch is null || _pixel is null)
        {
            base.Draw(gameTime);
            return;
        }

        var playBounds = GetPlayBounds();

        GraphicsDevice.Clear(new Color(7, 11, 18));

        _spriteBatch.Begin(samplerState: SamplerState.PointClamp);

        DrawBackground(playBounds);
        DrawStars();

        if (_mode is GameMode.Playing or GameMode.Paused or GameMode.GameOver)
        {
            DrawPlayer();
            DrawShots();
            DrawAsteroids();
            DrawHud(playBounds);
        }

        DrawOverlay(playBounds);

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private void StartMenuState()
    {
        _session.Reset();
        _shots.Clear();
        _asteroids.Clear();
        _spawnTimerSeconds = 0;
        _scoreRecorded = false;

        var bounds = GetPlayBounds();
        _player = new PlayerShip(new Vector2(bounds.Center.X, bounds.Bottom - 90f));

        _mode = GameMode.Menu;
        _statusMessage = "DRUECKE ENTER NEUER RUN";
        RefreshHighScores();
    }

    private void StartNewRun(Rectangle playBounds)
    {
        _session.Reset();
        _shots.Clear();
        _asteroids.Clear();
        _spawnTimerSeconds = 0;
        _scoreRecorded = false;

        _player = new PlayerShip(new Vector2(playBounds.Center.X, playBounds.Bottom - 90f));
        _pilotName = string.IsNullOrWhiteSpace(_pilotName)
            ? GameSettings.DefaultPilotName
            : _pilotName.Trim();

        _mode = GameMode.Playing;
        _statusMessage = "WASD ODER PFEILE SPACE SCHIESSEN P PAUSE";
    }

    private void UpdatePlaying(float deltaSeconds, Rectangle playBounds)
    {
        _session.AddSurvivalTime(deltaSeconds);
        _player.Update(deltaSeconds, _inputService.MovementDirection, playBounds);

        if (_inputService.IsShootPressed)
        {
            var shot = _player.TryShoot();
            if (shot is not null)
            {
                _shots.Add(shot);
            }
        }

        for (var index = _shots.Count - 1; index >= 0; index--)
        {
            var shot = _shots[index];
            shot.Update(deltaSeconds);

            if (shot.IsOutOfBounds(playBounds))
            {
                _shots.RemoveAt(index);
            }
        }

        _spawnTimerSeconds += deltaSeconds;
        if (_spawnTimerSeconds >= _session.SpawnIntervalSeconds)
        {
            _spawnTimerSeconds = 0;
            _asteroids.Add(_spawnService.CreateAsteroid(_session, playBounds));
        }

        for (var index = _asteroids.Count - 1; index >= 0; index--)
        {
            var asteroid = _asteroids[index];
            asteroid.Update(deltaSeconds);

            if (asteroid.HasPassedBottom(playBounds))
            {
                _asteroids.RemoveAt(index);
                _session.RemoveLife();
                continue;
            }

            if (asteroid.HasLeftHorizontalBounds(playBounds))
            {
                _asteroids.RemoveAt(index);
                continue;
            }

            if (_collisionService.PlayerHitsAsteroid(_player, asteroid))
            {
                _asteroids.RemoveAt(index);
                _session.RemoveLife();
            }
        }

        if (_session.IsGameOver)
        {
            HandleGameOver();
            return;
        }

        ResolveShotCollisions();
    }

    private void ResolveShotCollisions()
    {
        for (var asteroidIndex = _asteroids.Count - 1; asteroidIndex >= 0; asteroidIndex--)
        {
            var asteroid = _asteroids[asteroidIndex];
            var asteroidDestroyed = false;

            for (var shotIndex = _shots.Count - 1; shotIndex >= 0; shotIndex--)
            {
                var shot = _shots[shotIndex];
                if (!_collisionService.ShotHitsAsteroid(shot, asteroid))
                {
                    continue;
                }

                _shots.RemoveAt(shotIndex);
                _session.AddScore(asteroid.ScoreValue);
                asteroidDestroyed = true;
                break;
            }

            if (asteroidDestroyed)
            {
                _asteroids.RemoveAt(asteroidIndex);
            }
        }
    }

    private void HandleGameOver()
    {
        _mode = GameMode.GameOver;

        if (_scoreRecorded)
        {
            return;
        }

        var addedToTopList = _highScoreService.Record(_pilotName, _session.Score, _session.Level);
        RefreshHighScores();
        _scoreRecorded = true;

        _statusMessage = addedToTopList
            ? "NEUER HIGHSCORE EINTRAG GESPEICHERT"
            : "RUN BEENDET ENTER NEUSTART ESC MENUE";
    }

    private void HandlePilotNameInput(KeyboardState keyboardState)
    {
        foreach (var key in keyboardState.GetPressedKeys())
        {
            if (_previousKeyboardState.IsKeyDown(key))
            {
                continue;
            }

            if (key == Keys.Back)
            {
                if (_pilotName.Length > 0)
                {
                    _pilotName = _pilotName[..^1];
                }

                continue;
            }

            if (!TryMapKeyToCharacter(key, out var value))
            {
                continue;
            }

            if (_pilotName.Length >= MaxPilotNameLength)
            {
                continue;
            }

            if (value == ' ' && (_pilotName.Length == 0 || _pilotName[^1] == ' '))
            {
                continue;
            }

            _pilotName += value;
        }
    }

    private static bool TryMapKeyToCharacter(Keys key, out char character)
    {
        if (key >= Keys.A && key <= Keys.Z)
        {
            character = (char)('A' + (key - Keys.A));
            return true;
        }

        if (key >= Keys.D0 && key <= Keys.D9)
        {
            character = (char)('0' + (key - Keys.D0));
            return true;
        }

        if (key >= Keys.NumPad0 && key <= Keys.NumPad9)
        {
            character = (char)('0' + (key - Keys.NumPad0));
            return true;
        }

        if (key is Keys.Space)
        {
            character = ' ';
            return true;
        }

        if (key is Keys.OemMinus or Keys.Subtract)
        {
            character = '-';
            return true;
        }

        character = default;
        return false;
    }

    private void UpdateStars(float deltaSeconds, Rectangle playBounds)
    {
        if (_stars.Count == 0)
        {
            _spawnService.PopulateStars(_stars, playBounds);
        }

        foreach (var star in _stars)
        {
            star.Update(deltaSeconds);
            if (star.PassedBottom(playBounds))
            {
                _spawnService.RecycleStar(star, playBounds);
            }
        }
    }

    private void RefreshHighScores()
    {
        _highScores.Clear();
        foreach (var entry in _highScoreService.Load().Take(5))
        {
            _highScores.Add(entry);
        }
    }

    private Rectangle GetPlayBounds()
    {
        return GraphicsDevice?.Viewport.Bounds ?? new Rectangle(0, 0, GameSettings.WindowWidth, GameSettings.WindowHeight);
    }

    private void DrawBackground(Rectangle playBounds)
    {
        DrawRect(playBounds, new Color(7, 11, 18));

        var horizon = new Rectangle(playBounds.Left, playBounds.Top, playBounds.Width, (int)(playBounds.Height * 0.2f));
        DrawRect(horizon, new Color(13, 20, 34) * 0.7f);

        var bottomGlow = new Rectangle(playBounds.Left, playBounds.Bottom - 90, playBounds.Width, 90);
        DrawRect(bottomGlow, new Color(16, 34, 48) * 0.55f);
    }

    private void DrawStars()
    {
        foreach (var star in _stars)
        {
            var size = Math.Max(1, (int)star.Size);
            var color = new Color(star.Brightness, star.Brightness, star.Brightness, 1f);
            var starRect = new Rectangle((int)star.Position.X, (int)star.Position.Y, size, size);
            DrawRect(starRect, color);
        }
    }

    private void DrawPlayer()
    {
        var x = _player.Position.X;
        var y = _player.Position.Y;

        var leftWing = new Rectangle((int)(x - (_player.Width * 0.5f)), (int)(y - (_player.Height * 0.2f)), (int)(_player.Width * 0.32f), (int)(_player.Height * 0.58f));
        var rightWing = new Rectangle((int)(x + (_player.Width * 0.18f)), (int)(y - (_player.Height * 0.2f)), (int)(_player.Width * 0.32f), (int)(_player.Height * 0.58f));
        var core = new Rectangle((int)(x - (_player.Width * 0.16f)), (int)(y - (_player.Height * 0.5f)), (int)(_player.Width * 0.32f), (int)_player.Height);
        var canopy = new Rectangle((int)(x - (_player.Width * 0.1f)), (int)(y - (_player.Height * 0.37f)), (int)(_player.Width * 0.2f), (int)(_player.Height * 0.28f));

        DrawRect(leftWing, new Color(74, 162, 242));
        DrawRect(rightWing, new Color(74, 162, 242));
        DrawRect(core, new Color(217, 236, 255));
        DrawRect(canopy, new Color(122, 213, 255));
    }

    private void DrawShots()
    {
        foreach (var shot in _shots)
        {
            var trail = new Rectangle((int)(shot.Position.X - (shot.Width * 0.5f)), (int)shot.Position.Y, (int)shot.Width, (int)shot.Height);
            DrawRect(trail, new Color(92, 234, 199));
        }
    }

    private void DrawAsteroids()
    {
        foreach (var asteroid in _asteroids)
        {
            var size = (int)asteroid.Size;
            var body = new Rectangle((int)(asteroid.Position.X - (size * 0.5f)), (int)(asteroid.Position.Y - (size * 0.5f)), size, size);
            var core = new Rectangle((int)(asteroid.Position.X - (size * 0.22f)), (int)(asteroid.Position.Y - (size * 0.22f)), (int)(size * 0.44f), (int)(size * 0.44f));

            DrawRect(body, new Color(153, 111, 86));
            DrawRect(core, new Color(226, 188, 153));
        }
    }

    private void DrawHud(Rectangle playBounds)
    {
        var topText = $"SCORE {_session.Score}  LIVES {_session.Lives}  LEVEL {_session.Level}  TIME {_session.SurvivalSeconds:0.0}";
        DrawText(topText, new Vector2(playBounds.Left + 22, playBounds.Top + 16), 2, Color.White);

        var cooldownBarX = playBounds.Left + 22;
        var cooldownBarY = playBounds.Top + 40;
        var cooldownWidth = 170;
        var cooldownHeight = 10;

        DrawRect(new Rectangle(cooldownBarX, cooldownBarY, cooldownWidth, cooldownHeight), new Color(46, 61, 79));
        DrawRect(
            new Rectangle(cooldownBarX, cooldownBarY, (int)(cooldownWidth * _player.CooldownRatio), cooldownHeight),
            new Color(92, 234, 199));
    }

    private void DrawOverlay(Rectangle playBounds)
    {
        switch (_mode)
        {
            case GameMode.Menu:
                DrawCenteredText("ORBIT DEFENDER", playBounds.Center.X, playBounds.Top + 120, 4, new Color(156, 226, 255));
                DrawCenteredText("FLAGSHIP C SHARP GAME MONOGAME", playBounds.Center.X, playBounds.Top + 182, 2, Color.White);
                DrawCenteredText("ENTER START", playBounds.Center.X, playBounds.Top + 228, 2, new Color(170, 255, 220));
                DrawCenteredText("WASD ODER PFEILE  SPACE SCHIESSEN  P PAUSE", playBounds.Center.X, playBounds.Top + 264, 1, new Color(200, 211, 224));
                DrawCenteredText(_statusMessage, playBounds.Center.X, playBounds.Top + 286, 1, new Color(140, 195, 255));
                DrawCenteredText($"PILOT NAME {_pilotName}", playBounds.Center.X, playBounds.Top + 312, 2, new Color(255, 241, 194));
                DrawCenteredText("NAME TIPPEN  BACKSPACE LOESCHT", playBounds.Center.X, playBounds.Top + 346, 1, new Color(194, 207, 222));

                DrawCenteredText("TOP 5 HIGHSCORES", playBounds.Center.X, playBounds.Top + 380, 2, new Color(255, 223, 165));
                DrawHighScoreList(playBounds.Center.X, playBounds.Top + 420);
                break;
            case GameMode.Paused:
                DrawRect(playBounds, new Color(4, 5, 8) * 0.55f);
                DrawCenteredText("PAUSE", playBounds.Center.X, playBounds.Center.Y - 25, 4, Color.White);
                DrawCenteredText("ENTER ODER P FORTSETZEN", playBounds.Center.X, playBounds.Center.Y + 36, 2, new Color(170, 255, 220));
                break;
            case GameMode.GameOver:
                DrawRect(playBounds, new Color(4, 5, 8) * 0.6f);
                DrawCenteredText("RUN BEENDET", playBounds.Center.X, playBounds.Center.Y - 96, 3, new Color(255, 191, 191));
                DrawCenteredText($"SCORE {_session.Score}  LEVEL {_session.Level}", playBounds.Center.X, playBounds.Center.Y - 48, 2, Color.White);
                DrawCenteredText(_statusMessage, playBounds.Center.X, playBounds.Center.Y - 14, 1, new Color(164, 214, 255));
                DrawCenteredText("ENTER NEUSTART  ESC MENUE", playBounds.Center.X, playBounds.Center.Y + 24, 2, new Color(170, 255, 220));
                DrawHighScoreList(playBounds.Center.X, playBounds.Center.Y + 92);
                break;
        }
    }

    private void DrawHighScoreList(float centerX, float startY)
    {
        if (_highScores.Count == 0)
        {
            DrawCenteredText("NOCH KEINE EINTRAEGE", centerX, startY, 1, new Color(200, 211, 224));
            return;
        }

        for (var index = 0; index < _highScores.Count; index++)
        {
            var entry = _highScores[index];
            var line = $"{index + 1}. {entry.PlayerName.ToUpperInvariant()}  {entry.Score} P  L{entry.Level}";
            DrawCenteredText(line, centerX, startY + (index * 22), 1, new Color(214, 223, 236));
        }
    }

    private void DrawRect(Rectangle rectangle, Color color)
    {
        if (_spriteBatch is null || _pixel is null)
        {
            return;
        }

        _spriteBatch.Draw(_pixel, rectangle, color);
    }

    private void DrawCenteredText(string text, float centerX, float y, int scale, Color color)
    {
        var width = MeasureTextWidth(text, scale);
        var position = new Vector2(centerX - (width * 0.5f), y);
        DrawText(text, position, scale, color);
    }

    private void DrawText(string text, Vector2 position, int scale, Color color)
    {
        if (scale <= 0)
        {
            return;
        }

        var cursorX = position.X;
        var upperText = text.ToUpperInvariant();

        foreach (var character in upperText)
        {
            var glyph = PixelFont.TryGetValue(character, out var resolvedGlyph)
                ? resolvedGlyph
                : PixelFont['?'];

            for (var row = 0; row < glyph.Length; row++)
            {
                for (var column = 0; column < glyph[row].Length; column++)
                {
                    if (glyph[row][column] != '1')
                    {
                        continue;
                    }

                    var pixelRect = new Rectangle(
                        (int)cursorX + (column * scale),
                        (int)position.Y + (row * scale),
                        scale,
                        scale);

                    DrawRect(pixelRect, color);
                }
            }

            cursorX += (glyph[0].Length + 1) * scale;
        }
    }

    private static float MeasureTextWidth(string text, int scale)
    {
        var width = 0f;
        var upperText = text.ToUpperInvariant();

        foreach (var character in upperText)
        {
            var glyph = PixelFont.TryGetValue(character, out var resolvedGlyph)
                ? resolvedGlyph
                : PixelFont['?'];

            width += (glyph[0].Length + 1) * scale;
        }

        if (width <= 0)
        {
            return 0;
        }

        return width - scale;
    }
}
