using System;

namespace TowerProtect.Domain.Inventions.Tools;

public class ChanceProbe(Random rng)
{
    private readonly double _rand = rng.NextDouble();
    private double _ptr = 0.0;
    private bool _done = false;

    public bool If(double rate, Action action)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(rate, nameof(rate));

        if (_done)
        {
            return false;
        }

        _ptr += rate;

        if (_rand < _ptr)
        {
            action();
            return _done = true;
        }

        return false;
    }
}
