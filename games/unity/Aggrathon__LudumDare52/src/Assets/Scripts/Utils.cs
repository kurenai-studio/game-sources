using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Utils
{
    public static float SecondSmallest(float a, float b, float c, float d)
    {
        if (b < a)
        {
            (b, a) = (a, b);
        }
        if (d < c)
        {
            (d, c) = (c, d);
        }
        if (b < c)
        {
            return b;
        }
        if (c < a)
        {
            return a;
        }
        else
        {
            return c;
        }

    }

    public static bool SimilarColor(Color a, Color b, float threshold)
    {
        return Mathf.Abs(a.r - b.r) + Mathf.Abs(a.b - b.b) + Mathf.Abs(a.g - b.g) < threshold;
    }
}
