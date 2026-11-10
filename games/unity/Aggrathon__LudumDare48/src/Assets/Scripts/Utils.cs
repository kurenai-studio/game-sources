
using System.Collections.Generic;
using UnityEngine;

static class MyExtensions
{
    public static void Shuffle<T>(this IList<T> list)
    {
        int n = list.Count;
        while (n > 1)
        {
            int k = Random.Range(0, n);
            n--;
            T value = list[k];
            list[k] = list[n];
            list[n] = value;
        }
    }

    public static T Sample<T>(this IList<T> list)
    {
        return list[Random.Range(0, list.Count)];
    }
}
