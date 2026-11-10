
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public static class Utils
{

    public static void ShuffleList<A>(List<A> list)
    {
        for (int i = 0; i < list.Count - 1; i++)
        {
            SwapList(list, i, UnityEngine.Random.Range(i, list.Count));
        }
    }

    public static void SwapList<A>(List<A> list, int a, int b)
    {
        if (a != b)
        {
            var tmp = list[a];
            list[a] = list[b];
            list[b] = tmp;
        }
    }
    
    public static Vector3 GetGroundIntersect(Ray ray, float height) {
        if (height > ray.origin.y)
            return ray.origin;
        height =  - (ray.origin.y - height) / ray.direction.y;
        return ray.origin + ray.direction * height;
    }

    public static IEnumerator LerpMoveTo(Transform mover, Vector3 position, float time=0.5f) {
        Vector3 vel = Vector3.zero;
        while ((mover.position - position).sqrMagnitude > 0.03f) {
            mover.position = Vector3.SmoothDamp(mover.position, position, ref vel, time);
            yield return null;
        }
        mover.position = position;
        yield break;
    }

    public static bool Vector3InBox(Vector3 center, Vector3 limits, Vector3 other) {
        var diff = (center - other);
        diff = Vector3.Scale(diff, diff) - Vector3.Scale(limits, limits);
        return diff.x <= 0 & diff.y <= 0 & diff.z <= 0;
    }

    public static IEnumerator ExecuteNextFrame(System.Action act) {
        yield return null;
        act();
    }

    public static IEnumerator ExecuteLater(System.Action act, float time) {
        yield return new WaitForSeconds(time);
        act();
    }

    public static IEnumerator ChainIEnumerator(IEnumerator a, IEnumerator b) {
        yield return a;
        yield return b;
    }
}
