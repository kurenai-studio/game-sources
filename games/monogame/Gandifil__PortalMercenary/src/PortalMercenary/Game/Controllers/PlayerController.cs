using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGame.Extended;
using MonoGame.Extended.Input;

namespace PortalMercenary.Game.Controllers;

public class PlayerController : ICharacterController
{
    public void Update(Character character, float dt)
    {
        var keys = Keyboard.GetState();

        if (keys.IsKeyDown(Keys.Space))
            character.Attack();
        
        var move = Vector2.Zero;
        if (keys.IsKeyDown(Keys.W) || keys.IsKeyDown(Keys.Up))    move.Y -= 1;
        if (keys.IsKeyDown(Keys.S) || keys.IsKeyDown(Keys.Down))   move.Y += 1;
        if (keys.IsKeyDown(Keys.A) || keys.IsKeyDown(Keys.Left))   move.X -= 1;
        if (keys.IsKeyDown(Keys.D) || keys.IsKeyDown(Keys.Right))  move.X += 1;
        character.Actor.Shift = move == Vector2.Zero ? move : move.NormalizedCopy();
        character.IsRunning = keys.IsKeyDown(Keys.LeftShift);
    }
}