using Microsoft.Xna.Framework;
using System;
using System.Threading;
using TowerProtect.Domain.Inventions.Synchronization;

namespace TowerProtect.Framework.Other;

internal class SynchronizationComponent(
    Game game,
    GameSynchronizationContext syncContext) : GameComponent(game)
{
    public override void Initialize()
    {
        SynchronizationContext.SetSynchronizationContext(syncContext);
        Console.WriteLine("Synchronization context has been initialized.");

        base.Initialize();
    }

    public override void Update(GameTime gameTime)
    {
        syncContext.ProcessPending();
        base.Update(gameTime);
    }
}
