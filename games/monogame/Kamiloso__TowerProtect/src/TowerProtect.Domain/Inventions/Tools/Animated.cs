using System;
using System.Diagnostics;

namespace TowerProtect.Domain.Inventions.Tools;

public class Animated<T>(Func<long, T> animate)
{
    public T Evaluate(Stopwatch stopwatch)
        => animate(stopwatch.ElapsedMilliseconds);
}
