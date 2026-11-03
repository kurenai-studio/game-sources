using System;

namespace TowerProtect.Domain.Inventions.Tools;

internal class Swap<T>() where T : class, new()
{
    public T Current { get; private set; } = new();
    public T Other { get; private set; } = new();

    public void Exchange()
    {
        (Current, Other) = (Other, Current);
    }
}
