using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended;
using MonoGame.Extended.Animations;
using MonoGame.Extended.Graphics;

namespace PortalMercenary.Graphics.Animations;

public class TempAnimatedSpriteComponent: SimpleDrawableGameComponent
{
    private readonly Game1 _game;
    private readonly List<Animation> _animatedSprites = new();

    private class Animation
    {
        public AnimatedSprite AnimatedSprite { get; set; }

        public Vector2 Position { get; set; }

        public float Rotation { get; set; }
        
        public bool IsFinished {get; set;}
    }

    public TempAnimatedSpriteComponent(Game1 game)
    {
        _game = game;
    }

    public void Spawn(SpriteSheet spriteSheet, string key, Vector2 position, float rotation)
    {
        var sprite = new AnimatedSprite(spriteSheet); 
        sprite.SetAnimation(key).OnAnimationEvent += OnOnAnimationEvent;
        sprite.OriginNormalized = Vector2.One / 2;
        
        _animatedSprites.Add(new Animation()
        {
            AnimatedSprite = sprite,
            Position = position,
            Rotation = rotation,
        });
    }

    private void OnOnAnimationEvent(IAnimationController controller, AnimationEventTrigger trigger)
    {
        if (trigger == AnimationEventTrigger.AnimationCompleted)
        {
            controller.OnAnimationEvent -= OnOnAnimationEvent;
            _animatedSprites.Find(s => s.AnimatedSprite.Controller == controller).IsFinished = true;
        }
    }

    public override void Update(GameTime gameTime)
    {
        foreach (var animation in _animatedSprites)
            animation.AnimatedSprite.Update(gameTime);
        _animatedSprites.RemoveAll(x => x.IsFinished);
    }

    public override void Draw(GameTime gameTime)
    {
        G.Game.SpriteBatch.Begin(samplerState: SamplerState.PointClamp);
        foreach (var animation in _animatedSprites)
            _game.SpriteBatch.Draw(animation.AnimatedSprite, animation.Position, animation.Rotation); 
        G.Game.SpriteBatch.End();
    }
}