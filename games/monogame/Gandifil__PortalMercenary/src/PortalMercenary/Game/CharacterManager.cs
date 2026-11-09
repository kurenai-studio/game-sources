using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended;
using PortalMercenary.Game.Controllers;

namespace PortalMercenary.Game;

public class CharacterManager: SimpleDrawableGameComponent
{
    private readonly Game1 _game;
    private readonly List<Character> _characters = new();
    private List<Slice> _slices = new();
    private readonly SpriteBatch _spriteBatch;

    public CharacterManager(Game1 game)
    {
        _game = game;
        _spriteBatch = new SpriteBatch(game.GraphicsDevice);
    }

    private Effect _cutEffect;

    protected override void LoadContent()
    {
        base.LoadContent();

        _cutEffect = G.Content.Effects["cutEffect"];
    }

    public CharacterSpawner GetSpawner() => new (this);

    public Character Add(Character character)
    {
        _characters.Add(character);
        G.Screen.CollisionWorld.Insert(character);
        return character;
    }

    public void Add(Slice slice)
    {
        _slices.Add(slice);
    }

    public event Action CharacterRemoved;
    
    public override void Update(GameTime gameTime)
    {
        var dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        foreach (var item in _slices)
            item.Update(dt);
        foreach (var item in _characters)
            item.Update(dt);

        var charactersToRemove = _characters.Where(x => !x.IsAlive).ToList();
        foreach (var item in charactersToRemove)
            G.Screen.CollisionWorld.Remove(item);
        var count = _characters.RemoveAll(x => !x.IsAlive);
        for (var i = 0; i < count; i++)
        {
            CharacterRemoved?.Invoke();
        }
        _characters.Sort((x, y) => x.Position.Y.CompareTo(y.Position.Y));
        
        G.Screen.CollisionWorld.RebuildDynamicLayers();
    }

    public override void Draw(GameTime gameTime)
    {
        _spriteBatch.Begin(samplerState: SamplerState.PointClamp, effect: _cutEffect, transformMatrix: G.Game.Camera.GetViewMatrix());
        foreach (var item in _slices)
            item.Draw(_spriteBatch);
        foreach (var item in _characters)
            item.Draw(_spriteBatch);
        _spriteBatch.End();
    }
}