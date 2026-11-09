using Monogame.Enchanted.Collections;

namespace Monogame.Enchanted.Debug;

internal class FrameCounter: IFloatUpdatable
{
    public readonly CircularQueue<float> DeltaTimes = new(256);
    
    public void Update(float dt)
    {
        DeltaTimes.Enqueue(dt);
        for (int i = 1; i < 5; i++)
        {
            DeltaTimes[i] = 0;
        }
    }
}