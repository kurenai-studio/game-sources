using System;
using System.Collections.Generic;

namespace TowerProtect.Domain.Inventions.Tools;

public class LazyProvider<TKey, TValue>(Func<TKey, TValue> factory)
    where TKey : notnull
{
    private readonly Dictionary<TKey, TValue> _dict = [];

    public TValue this[TKey key] => _dict.TryGetValue(key, out var value)
        ? value
        : _dict[key] = factory(key);
}
