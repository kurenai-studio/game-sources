using System;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Monogame.Enchanted.Debug;
using MonoGame.Extended;
using MonoGame.Extended.Tweening;
using PortalMercenary.Game.Controllers;
using PortalMercenary.Graphics.Actors;
using PortalMercenary.Graphics.Extensions;
using PortalMercenary.Utils;

namespace PortalMercenary.Game;

public class Character: Entity
{
    public readonly CharacterOptions Options;
    private readonly AttackProcessor _attackProcessor;
    
    public Actor Actor { get; set; }

    public required ICharacterController Controller { get; init; }

    public bool IsRunning { get; set; }

    public Character(Vector2 position, CharacterOptions options): base(position)
    {
        Options = options;
        DebugHelper.Inspect(Options);
        _attackProcessor = new AttackProcessor(options.Attack);
        Actor = new Actor(this, G.Content.FreeTexPackerSpritesheets[options.Atlas].ToTexture2DAtlas());
        Actor.Unheaded += Die;
    }

    public override void Update(float dt)
    {
        var oldPosition = Position;
        Controller.Update(this, dt);

        var speed = IsRunning ? Options.RunMovementSpeed : Options.MovementSpeed;
        Position += Actor.Shift * speed * dt;
        
        if (G.Screen.CollisionWorld.QueryCollisions(this, CollisionWorldExtensions.LAYER_NAME).Any() ||
            G.Screen.CollisionWorld.QueryCollisions(this, null).Any())
        {
            Position = oldPosition;
        }
        Actor.Update(IsRunning ? 3*dt : dt);
    }

    public void Draw(SpriteBatch gameSpriteBatch)
    {
        DebugHelper.DrawCircle(gameSpriteBatch, Position, 20);
        Actor.Draw(gameSpriteBatch);
    }

    public void Attack()
    {
        if (Actor.IsFree)
        {
            _attackProcessor.Execute(this);
        }
    }

    public void Damage(Vector2 pos)
    {
        G.Tweener.TweenTo(
                target: this, 
                expression: x => x.Position, 
                toValue: Position + pos, 
                duration: .1f,  
                delay: 0)
            .Easing(EasingFunctions.ElasticOut);
        G.Screen.DecalsComponent.Add(Position);
        G.Content.Sounds[Options.DamageSounds[Random.Shared.Next(Options.DamageSounds.Length)]].Play(.25f, 0, 1);

        // Создаем эффект крови
        G.Screen.BloodManager.SpawnBlood(Position, pos);

        Actor.CutAnything();
    }

    public override CollisionShape2D Shape
    {
        get
        {
            var bounds = new BoundingCircle2D(Position, 20);
            return new CollisionShape2D(bounds);
        }
    }
}