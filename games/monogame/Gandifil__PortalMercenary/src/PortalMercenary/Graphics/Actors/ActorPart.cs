using System;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended.Graphics;
using PortalMercenary.Game;

namespace PortalMercenary.Graphics.Actors;

public class ActorPart
{
    private readonly Actor _actor;
    public readonly CuttingSprite[] Sprites;
    private Vector2 GlobalPosition => _actor.Position + Shift + Position;

    public Vector2 Position { get; set; }
    public float Rotation { get; set; }
    public float Depth { get; set; }
    public Vector2 Shift { get; set; }
    
    public bool IsCut {get; private set; }
    public bool IsDetached {get; private set; }
    
    public ActorPart(Actor actor, Sprite[] sprites)
    {
        _actor = actor;
        Sprites = sprites.Select(x => new CuttingSprite(x)).ToArray();
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        if (IsDetached)
            return;
        var sprite = Sprites[(int)_actor.Direction];
        sprite.Draw(spriteBatch, GlobalPosition, Rotation, Vector2.One);
    }
    
    public void Cut(CuttingSprite.Direction direction)
    {
        IsCut = true;
        foreach (var sprite in Sprites)
            sprite.Cut(direction);
        var reversed = Sprites[(int)_actor.Direction].GetReversed();
        var impulse = new Vector2(Random.Shared.Next(-100, 100),  Random.Shared.Next(-100, 100));
        G.Screen.CharacterManager.Add(new Slice(reversed, GlobalPosition, impulse, 100f));
    }

    public void Detach()
    {
        var impulse = new Vector2(Random.Shared.Next(-100, 100),  Random.Shared.Next(-100, 100));
        G.Screen.CharacterManager.Add(new Slice(Sprites[(int)_actor.Direction], GlobalPosition, impulse, 100f));
        IsDetached = true;
    }
}