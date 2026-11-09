using System;
using System.Collections.Generic;
using System.Linq;
using Coroutine;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended;
using MonoGame.Extended.Collisions;
using MonoGame.Extended.Collisions.Layers;
using MonoGame.Extended.Screens;
using MonoGame.Extended.Screens.Transitions;
using MonoGame.Extended.Tilemaps;
using MonoGame.Extended.Tilemaps.Rendering;
using PortalMercenary.Game;
using PortalMercenary.Game.Controllers;
using PortalMercenary.Graphics;
using PortalMercenary.Graphics.Animations;
using PortalMercenary.Utils;

namespace PortalMercenary.Screens;

public class TilemapGameScreen: GameScreen
{
    public const float MAX_TIME = 180;
    
    private readonly string _mapName;
    private readonly TilemapSpriteBatchRenderer _renderer;
    private readonly SpriteBatch _spriteBatch;
    public Character Player { get; private set; }

    public CollisionWorld2D CollisionWorld { get; private set; }
    
    public CharacterManager CharacterManager { get; private set; }

    public DecalsComponent DecalsComponent { get; private set; }
    
    public TempAnimatedSpriteComponent Animations { get; private set; }
    
    public BloodManager BloodManager { get; private set; }
    
    private GameStats _gameStats;
    private Tilemap _tilemap;
    private SpriteFont _font;

    public TilemapGameScreen(string mapName) : base(G.Game)
    {
        _mapName = mapName;

        _renderer = new TilemapSpriteBatchRenderer();
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        CollisionWorld = new CollisionWorld2D(new Layer(new SpatialHash(new SizeF(128f, 128f))));
        G.ScreenInit(this);
    }

    public override void Initialize()
    {
        G.Game.Components.Add(DecalsComponent = new DecalsComponent(100));
        G.Game.Components.Add(Animations = new TempAnimatedSpriteComponent(G.Game));
        G.Game.Components.Add(BloodManager = new BloodManager());
        G.Game.Components.Add(CharacterManager = new CharacterManager(G.Game));
    }

    public override void LoadContent()
    {
        base.LoadContent();
        
        _font = G.Game.Content.Load<SpriteFont>("fonts/04B_30");
        _tilemap = Content.Load<Tilemap>(_mapName);
        _renderer.LoadTilemap(_tilemap);
        CollisionWorld.AddTilemapCollision(_tilemap);
        
        var spawnPoints = _tilemap.Layers["spawners"] as TilemapObjectLayer ?? throw new Exception("spawners not found");

        var spawner = CharacterManager.GetSpawner();
        Player = spawner
            .WithPosition(spawnPoints.Objects[0].Position)
            .WithController(new PlayerController())
            .Spawn("player")
            .Last();

        CharacterManager.CharacterRemoved += () => _gameStats.Kills++;
        CoroutineHandler.Start(Spawn(spawner, 
            spawnPoints.Objects.Where(x => x.Id != 1).Select(x => x.Position).ToArray()));
    }

    private IEnumerator<Wait> Spawn(CharacterSpawner spawner, Vector2[] positions)
    {
        spawner.WithController(new AiController());

        for (var minutes = 0; minutes < 3; minutes++)
        {
            for (var seconds = 0; seconds < 60; seconds+=10)
            {
                for (var i = 0; i < (minutes+1); i++)
                {
                    spawner.WithPosition(Random.Shared.GetItems(positions, 1)[0]).Spawn("player");
                }
                yield return new Wait(10);
            }
        }
    }
    
    public override void Update(GameTime gameTime)
    {
        if (_gameStats.IsWin is null && _gameStats.Time > MAX_TIME)
        {
            _gameStats.IsWin = true;
            G.Game.ScreenManager.ReplaceScreen(
                new ResultGameScreen(_gameStats), 
                new FadeTransition(G.Game.GraphicsDevice, ResultGameScreen.BACKGROUND_COLOR,5f));
        }
        else
            _gameStats.Time += gameTime.GetElapsedSeconds();
        _renderer.Update(gameTime);
        G.Game.Camera.LookAt(Player.Position);
    }

    public override void Draw(GameTime gameTime)
    {
        _renderer.Draw(_spriteBatch, G.Game.Camera);
        
        var time = (int)(MAX_TIME - _gameStats.Time);
        
        _spriteBatch.Begin();
        _spriteBatch.DrawString(_font, $"SURVIVE! {TimeSpan.FromSeconds(time)} REMAINING", new Vector2(10, 10), Color.White);
        _spriteBatch.DrawString(_font, $"YOU MADE {_gameStats.Kills} KILLS", new Vector2(10, 50), Color.White);
        _spriteBatch.End();
    }

    public override void Dispose()
    {
        base.Dispose();
        
        G.Game.Components.Remove(DecalsComponent);
        G.Game.Components.Remove(Animations);
        G.Game.Components.Remove(BloodManager);
        G.Game.Components.Remove(CharacterManager);
    }
}