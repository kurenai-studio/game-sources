
using System.Collections.Generic;
using UnityEngine;

public static class Utils
{
    public static void Shuffle<T>(this IList<T> list)
    {
        var count = list.Count;
        var last = count - 1;
        for (var i = 0; i < last; ++i)
        {
            var r = Random.Range(i, count);
            var tmp = list[i];
            list[i] = list[r];
            list[r] = tmp;
        }
    }

    public static T Sample<T>(this IList<T> list)
    {
        if (list.Count > 0)
            return list[Random.Range(0, list.Count)];
        else
            return default(T);
    }
}