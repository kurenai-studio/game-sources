using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using DungeonExplorer.Core;
using DungeonExplorer.Systems;
using DungeonExplorer.World;
using DungeonExplorer.Entities;
using DungeonExplorer.Data;
using System.Collections.Generic;
using System;
using System.Diagnostics;

namespace DungeonExplorer
{
    /// <summary>
    /// Classe principale del gioco che gestisce il loop di gioco e coordina tutti i sistemi
    /// </summary>
    public class DungeonExplorer : Game
    {
        private GraphicsDeviceManager _graphics;
        private SpriteBatch _spriteBatch;

        // Core Systems
        private GameManager _gameManager;
        private InputManager _inputManager;
        private Camera2D _camera;

        // ECS Systems
        private RenderSystem _renderSystem;
        private MovementSystem _movementSystem;
        private AISystem _aiSystem;
        private CollisionSystem _collisionSystem;

        // World
        private Dungeon _currentDungeon;
        private DungeonGenerator _dungeonGenerator;

        // Entities
        private Player _player;
        private List<Enemy> _enemies;
        private List<Treasure> _treasures;

        // Content
        private Dictionary<string, Texture2D> _textures;
        private SpriteFont _font;

        // Game State
        private bool _gameStarted;

        public DungeonExplorer()
        {
            Console.WriteLine("Starting...");
            _graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
            
            // Set window size
            _graphics.PreferredBackBufferWidth = 1920;
            _graphics.PreferredBackBufferHeight = 1080;
        }

        protected override void Initialize()
        {
            // Initialize core systems
            Console.WriteLine("Launching Input Manager...");
            _inputManager = new InputManager();
            Console.WriteLine("Done.");
            Console.WriteLine("Creating Camera...");
            _camera = new Camera2D(GraphicsDevice.Viewport);
            Console.WriteLine("Done.");
            Console.WriteLine("Launching Game Manager...");
            _gameManager = new GameManager();
            Console.WriteLine("Done.");
            
            // Initialize ECS systems
            Console.WriteLine("Launching Render System...");
            _renderSystem = new RenderSystem();
            Console.WriteLine("Done.");
            Console.WriteLine("Launching Movement System...");
            _movementSystem = new MovementSystem();
            Console.WriteLine("Done.");
            Console.WriteLine("Launching AI System...");
            _aiSystem = new AISystem();
            Console.WriteLine("Done.");
            Console.WriteLine("Launching Collision System...");
            _collisionSystem = new CollisionSystem();
            Console.WriteLine("Done.");

            // Initialize collections
            Console.WriteLine("Initializing Textures...");
            _enemies = new List<Enemy>();
            _treasures = new List<Treasure>();
            _textures = new Dictionary<string, Texture2D>();
            Console.WriteLine("Done.");

            base.Initialize();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);

            // Load textures
            LoadTextures();

            // Load font
            _font = Content.Load<SpriteFont>("Fonts/DefaultFont");

            // Initialize dungeon generator
            _dungeonGenerator = new DungeonGenerator();

            // Start new game
            StartNewGame();
        }

        private void LoadTextures()
        {
            try
            {
                _textures["player"] = Content.Load<Texture2D>("Textures/player");
                _textures["enemy"] = Content.Load<Texture2D>("Textures/enemy");
                _textures["wall"] = Content.Load<Texture2D>("Textures/wall");
                _textures["floor"] = Content.Load<Texture2D>("Textures/floor");
                _textures["treasure"] = Content.Load<Texture2D>("Textures/treasure");
            }
            catch
            {
                // Create placeholder textures if files not found
                CreatePlaceholderTextures();
            }
        }

        private void CreatePlaceholderTextures()
        {
            // Create simple colored rectangles as placeholder textures
            _textures["player"] = CreateColorTexture(Color.Blue, 32, 32);
            _textures["enemy"] = CreateColorTexture(Color.Red, 32, 32);
            _textures["wall"] = CreateColorTexture(Color.Gray, 32, 32);
            _textures["floor"] = CreateColorTexture(Color.LightGray, 32, 32);
            _textures["treasure"] = CreateColorTexture(Color.Gold, 32, 32);
        }

        private Texture2D CreateColorTexture(Color color, int width, int height)
        {
            Texture2D texture = new Texture2D(GraphicsDevice, width, height);
            Color[] data = new Color[width * height];
            for (int i = 0; i < data.Length; i++)
                data[i] = color;
            texture.SetData(data);
            return texture;
        }

        private void StartNewGame()
        {
            // Generate new dungeon
            _currentDungeon = _dungeonGenerator.Generate(50, 30, 5, 15);

            // Create player at dungeon start position
            var startPosition = _currentDungeon.GetStartPosition();
            _player = new Player(startPosition * 32, _textures["player"]);

            // Clear existing entities
            _enemies.Clear();
            _treasures.Clear();

            // Spawn enemies and treasures
            SpawnEntities();

            // Center camera on player
            _camera.Follow(_player.Transform.Position);

            _gameStarted = true;
        }

        private void SpawnEntities()
        {
            var random = new Random();
            var rooms = _currentDungeon.GetRooms();

            // Spawn enemies (1-3 per room, excluding start room)
            for (int i = 1; i < rooms.Count; i++)
            {
                var room = rooms[i];
                int enemyCount = random.Next(1, 4);

                for (int j = 0; j < enemyCount; j++)
                {
                    var pos = room.GetRandomPosition();
                    var enemy = new Enemy(pos * 32, _textures["enemy"]);
                    _enemies.Add(enemy);
                }
            }

            // Spawn treasures (1 per room, excluding start room)
            for (int i = 1; i < rooms.Count; i++)
            {
                var room = rooms[i];
                var pos = room.GetRandomPosition();
                var treasure = new Treasure(pos * 32, _textures["treasure"]);
                _treasures.Add(treasure);
            }
        }

        protected override void Update(GameTime gameTime)
        {
            if (!_gameStarted) return;

            // Update input
            _inputManager.Update();

            // Handle exit
            if (_inputManager.IsKeyPressed(Keys.Escape))
                Exit();

            // Handle save/load
            if (_inputManager.IsKeyPressed(Keys.F5))
                SaveGame();
            if (_inputManager.IsKeyPressed(Keys.F9))
                LoadGame();

            // Handle new game
            if (_inputManager.IsKeyPressed(Keys.F2))
                StartNewGame();

            // Update systems
            _movementSystem.Update(gameTime, _player, _inputManager);
            
            // Update enemies AI
            foreach (var enemy in _enemies)
            {
                _aiSystem.Update(gameTime, enemy, _player, _currentDungeon);
            }

            // Handle collisions
            _collisionSystem.CheckPlayerEnemyCollisions(_player, _enemies);
            _collisionSystem.CheckPlayerTreasureCollisions(_player, _treasures);
            _collisionSystem.CheckWorldCollisions(_player, _currentDungeon);

            foreach (var enemy in _enemies)
            {
                _collisionSystem.CheckWorldCollisions(enemy, _currentDungeon);
            }

            // Update camera
            _camera.Follow(_player.Transform.Position);
            _camera.Update();

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.Black);

            _spriteBatch.Begin(transformMatrix: _camera.Transform);

            // Render world
            _renderSystem.RenderDungeon(_spriteBatch, _currentDungeon, _textures);

            // Render entities
            _renderSystem.RenderEntity(_spriteBatch, _player);
            
            foreach (var enemy in _enemies)
                _renderSystem.RenderEntity(_spriteBatch, enemy);
                
            foreach (var treasure in _treasures)
                _renderSystem.RenderEntity(_spriteBatch, treasure);

            _spriteBatch.End();

            // Render UI (not affected by camera transform)
            _spriteBatch.Begin();
            RenderUI();
            _spriteBatch.End();

            base.Draw(gameTime);
        }

        private void RenderUI()
        {
            string instructions = "WASD: Move | F2: New Game | F5: Save | F9: Load | ESC: Exit";
            string stats = $"Health: {_player.Health.CurrentHealth}/{_player.Health.MaxHealth} | " +
                          $"Score: {_gameManager.Score} | Treasures: {_gameManager.TreasuresCollected}";

            _spriteBatch.DrawString(_font, instructions, new Vector2(10, 10), Color.White);
            _spriteBatch.DrawString(_font, stats, new Vector2(10, 35), Color.White);

            if (_player.Health.CurrentHealth <= 0)
            {
                string gameOver = "GAME OVER - Press F2 to restart";
                var size = _font.MeasureString(gameOver);
                var pos = new Vector2(
                    (_graphics.PreferredBackBufferWidth - size.X) / 2,
                    (_graphics.PreferredBackBufferHeight - size.Y) / 2
                );
                _spriteBatch.DrawString(_font, gameOver, pos, Color.Red);
            }
        }

        private void SaveGame()
        {
            try
            {
                var saveManager = new SaveManager();
                var gameData = new GameData
                {
                    PlayerPosition = _player.Transform.Position,
                    PlayerHealth = _player.Health.CurrentHealth,
                    Score = _gameManager.Score,
                    TreasuresCollected = _gameManager.TreasuresCollected,
                    DungeonSeed = _dungeonGenerator.LastSeed,
                    EnemyPositions = _enemies.ConvertAll(e => e.Transform.Position),
                    TreasurePositions = _treasures.ConvertAll(t => t.Transform.Position)
                };

                saveManager.SaveGame(gameData, "savegame.json");
                // Could add UI feedback here
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Save failed: {ex.Message}");
            }
        }

        private void LoadGame()
        {
            try
            {
                var saveManager = new SaveManager();
                var gameData = saveManager.LoadGame("savegame.json");

                if (gameData != null)
                {
                    // Regenerate dungeon with same seed
                    _currentDungeon = _dungeonGenerator.Generate(50, 30, 5, 15, gameData.DungeonSeed);

                    // Restore player
                    _player.Transform.Position = gameData.PlayerPosition;
                    _player.Health.CurrentHealth = gameData.PlayerHealth;

                    // Restore game state
                    _gameManager.Score = gameData.Score;
                    _gameManager.TreasuresCollected = gameData.TreasuresCollected;

                    // Restore entities (simplified - in a full game you'd want more data)
                    _enemies.Clear();
                    _treasures.Clear();

                    for (int i = 0; i < gameData.EnemyPositions.Count; i++)
                    {
                        var enemy = new Enemy(gameData.EnemyPositions[i], _textures["enemy"]);
                        _enemies.Add(enemy);
                    }

                    for (int i = 0; i < gameData.TreasurePositions.Count; i++)
                    {
                        var treasure = new Treasure(gameData.TreasurePositions[i], _textures["treasure"]);
                        _treasures.Add(treasure);
                    }

                    _camera.Follow(_player.Transform.Position);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Load failed: {ex.Message}");
            }
        }
    }
}