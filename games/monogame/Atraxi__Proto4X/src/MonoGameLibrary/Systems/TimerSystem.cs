using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using System.Collections.Generic;

namespace MonoGameLibrary.Systems
{
    public class TimerSystem : IUpdateSystem
    {
        public IReadOnlyList<ComponentRef> RequiredComponentProviders => [ComponentRef.Of<Timer>()];

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var elapsedTicks = gameTime.ElapsedGameTime.Ticks;

            foreach (var archetypeChunk in archetypeChunks)
            {
                foreach(ref var timer in archetypeChunk.GetSpan<Timer>())
                {
                    if (timer.HasElapsed)
                    {
                        if (timer.ShouldRepeat)
                        {
                            timer.RemainingTicks += timer.DurationTicks;
                        }
                        else
                        {
                            continue;
                        }
                    }

                    timer.RemainingTicks -= elapsedTicks;
                }
            }
        }
    }
}
