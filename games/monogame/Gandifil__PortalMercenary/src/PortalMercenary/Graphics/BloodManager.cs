using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using MonoGame.Extended;
using MonoGame.Extended.Particles;
using MonoGame.Extended.Particles.Profiles;

namespace PortalMercenary.Graphics;

public class BloodManager: SimpleDrawableGameComponent
{
    private ParticleEffect _bloodEffect;
    
    public BloodManager()
    {
    }

    protected override void LoadContent()
    {
        base.LoadContent();
        _bloodEffect = G.Game.Content.Load<ParticleEffect>("effects/blood1");
    }

    /// <summary>
    /// Создает эффект крови в указанной позиции
    /// </summary>
    public void SpawnBlood(Vector2 position, Vector2 direction)
    {
        _bloodEffect.Position = position;
        (_bloodEffect.Emitters[0].Profile as SprayProfile)!.Direction = direction;
        _bloodEffect.Trigger();
    }
    
    public override void Update(GameTime gameTime)
    {
        _bloodEffect.Update(gameTime.GetElapsedSeconds());
    }
    
    public override void Draw(GameTime gameTime)
    {
        G.Game.SpriteBatch.Begin(transformMatrix:G.Game.Camera.GetViewMatrix());
        G.Game.SpriteBatch.Draw(_bloodEffect);
        G.Game.SpriteBatch.End();
    }
}
