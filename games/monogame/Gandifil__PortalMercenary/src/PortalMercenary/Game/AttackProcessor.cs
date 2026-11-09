using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using MonoGame.Extended;
using MonoGame.Extended.Collisions;
using MonoGame.Extended.Graphics;
using PortalMercenary.Graphics.Actors.Animations;

namespace PortalMercenary.Game;

public class AttackProcessor
{
    private readonly SoundEffect _contentSound;
    private readonly CharacterOptions.AttackOptions _options;
    private readonly SpriteSheet _contentSpritesheet;

    public AttackProcessor(CharacterOptions.AttackOptions options)
    {
        _options = options;
        _contentSpritesheet = G.Content.Spritesheets[_options.SpriteSheet];
        _contentSound = G.Content.Sounds[_options.Sound];
    }
    
    public void Execute(Character attacker)
    {
        var actor = attacker.Actor;
        var rotation = actor.Shift.ToAngle() - MathF.PI / 2;
        var localPosition = new Vector2(1, 0) * _options.Distance;
        localPosition.Rotate(rotation);
        var globalPosition = actor.Position + localPosition;

        var anim = new AttackAnimation()
        {
            Duration = _options.ActorAnimationDuration,
        };
        anim.ReachedHalf += AnimOnReachedHalf;
        
        void AnimOnReachedHalf(object sender, EventArgs e)
        {
            ((AttackAnimation)sender).ReachedHalf -= AnimOnReachedHalf;
            var collActor = new StrikeCollisionActor(globalPosition);
            G.Screen.CollisionWorld.Insert(collActor);
            foreach (var collision in G.Screen.CollisionWorld.QueryCollisions(collActor, null))
                if (collision.Other is Character other && other != attacker)
                    other.Damage(localPosition);
            G.Screen.CollisionWorld.Remove(collActor);
        }
        
        actor.Start(anim);
        G.Screen.Animations.Spawn(_contentSpritesheet, "Attack", globalPosition, rotation);
        _contentSound.Play();
    }

}
