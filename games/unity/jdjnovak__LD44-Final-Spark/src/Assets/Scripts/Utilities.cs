using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Utilities : MonoBehaviour
{
    public static float GetHypo(Vector2 v) {
        return Mathf.Sqrt(v.x*v.x + v.y*v.y);
    }
}
