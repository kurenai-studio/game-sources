using System;

namespace TowerProtect.Domain.Inventions.Tools;

public class LoopCycle(double interval)
{
    private double _accumulator;

    public void Invoke(double deltaTime, Action onCycle)
    {
        int frames = AccumulateFrames(deltaTime);
        for (int i = 0; i < frames; i++)
        {
            onCycle();
        }
    }

    public void StackInvoke(double deltaTime, Action<int> onCycle)
    {
        int frames = AccumulateFrames(deltaTime);
        if (frames > 0)
        {
            onCycle(frames);
        }
    }

    private int AccumulateFrames(double deltaTime)
    {
        _accumulator += deltaTime;

        if (_accumulator < interval)
            return 0;

        int frames = (int)(_accumulator / interval);
        _accumulator -= frames * interval;

        return frames;
    }
}
