using Clong.Core.Ports.Driving;
using Microsoft.Xna.Framework;
using DomainGameTime = Clong.Core.Domain.Dto.GameTime;

namespace Clong.Kni.Adapter.Driving;

/// <summary>
/// Adapter that delegates MonoGame's calls to Update and Draw to our game
/// </summary>
public class GameController(IForRunningTheGame game)
{
    public void Update(GameTime gameTime)
    {
        game.Update(
            new DomainGameTime {
                DeltaTime = gameTime.ElapsedGameTime,
                TotalTime = gameTime.TotalGameTime
            }
        );
    }

    public void Draw()
    {
        game.Draw();
    }
}