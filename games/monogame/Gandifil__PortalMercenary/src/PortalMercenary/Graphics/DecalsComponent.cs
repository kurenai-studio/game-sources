using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended;
using MonoGame.Extended.Graphics;

namespace PortalMercenary.Graphics;

public class DecalsComponent: SimpleDrawableGameComponent
{
    private struct Decal
    {
        public Vector2 Position { get; set; }
        public float Rotation { get; set; }
        public Sprite Sprite { get; set; }
        public bool IsActive { get; set; }
        public Vector2 Scale { get; set; }
    }
    
    private readonly Decal[] _decals;
    private int _index;
    private readonly Texture2DAtlas _textureAtlas;

    public DecalsComponent(int count)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(count);
        
        _decals = new Decal[count];
        _textureAtlas = Texture2DAtlas.Create("", G.Content.Textures["blood"], 64, 64);
    }

    public void Add(Vector2 position)
    {
        _decals[_index].Position = position;
        _decals[_index].Rotation = Random.Shared.NextSingle(MathF.PI * 2);
        _decals[_index].Sprite = _textureAtlas.CreateSprite(Random.Shared.Next(_textureAtlas.RegionCount));
        _decals[_index].Sprite.Color = Color.Gray;
        _decals[_index].IsActive = true;
        _decals[_index].Scale = Vector2.One;
        _index++;
        if (_index >= _decals.Length) 
            _index = 0;
    }
    
    public override void Update(GameTime gameTime)
    {
    }

    public override void Draw(GameTime gameTime)
    {
        G.Game.SpriteBatch.Begin(samplerState: SamplerState.PointClamp, transformMatrix: G.Game.Camera.GetViewMatrix());
        foreach (var decal in _decals)
            if (decal.IsActive)
                decal.Sprite.Draw(G.Game.SpriteBatch, decal.Position, decal.Rotation, decal.Scale);
        G.Game.SpriteBatch.End();
    }
}