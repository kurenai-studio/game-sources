using Microsoft.Xna.Community;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace CircusPop;

public class VelocityDisplay : DrawableGameComponent
{
    private IMovingObject subject = null;

    private PrimitiveBatch primitiveBatch;
    public VelocityDisplay(Game game) : base(game)
    {

    }

    public override void Initialize()
    {
        subject = Game.Services.GetService(typeof(IMovingObject)) as IMovingObject;

        base.Initialize();
    }

    protected override void LoadContent()
    {
        primitiveBatch = new PrimitiveBatch(GraphicsDevice);

        base.LoadContent();
    }

    /// <summary>
    /// Allows the game component to update itself.
    /// </summary>
    /// <param name="gameTime">Provides a snapshot of timing values.</param>
    public override void Update(GameTime gameTime)
    {
        base.Update(gameTime);
    }

    public override void Draw(GameTime gameTime)
    {
        primitiveBatch.Begin(PrimitiveType.LineList);
        primitiveBatch.AddVertex(subject.Position, Color.Blue);
        Vector2 nextSpot = subject.Position + (subject.Velocity * (float)gameTime.ElapsedGameTime.TotalSeconds) * 10;
        primitiveBatch.AddVertex(nextSpot, Color.Red);

        primitiveBatch.AddVertex(nextSpot, Color.Red);
        if (subject.Velocity.Y >= 0.0f)
        {
            nextSpot += new Vector2(-10.0f, -10.0f);
        }
        else
        {
            nextSpot += new Vector2(-10.0f, +10.0f);
        }
        primitiveBatch.AddVertex(nextSpot, Color.Red);
        primitiveBatch.End();

        base.Draw(gameTime);
    }

}
