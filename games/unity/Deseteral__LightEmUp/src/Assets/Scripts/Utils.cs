using System.Collections.Generic;
using UnityEngine;

namespace DefaultNamespace {
    public static class Utils {
        public static Vector3 MouseInWorld() {
            var v3 = Input.mousePosition;
            v3 = Camera.main.ScreenToWorldPoint(v3);
            v3.z = 0f;
            return v3;
        }

        public static void Shuffle<T>(this IList<T> list) {
            int n = list.Count;
            while (n > 1) {
                n--;
                int k = Random.Range(0, n);
                T value = list[k];
                list[k] = list[n];
                list[n] = value;
            }
        }

        public static (int, int) VectorToTilemapCoord(Vector2 vector) {
            return ((int) (vector.x - 0.5), (int) (vector.y - 0.5));
        }

        public static TV GetOrDefault<TK, TV>(this IDictionary<TK, TV> dict, TK key, TV defaultValue = default(TV)) {
            TV value;
            return dict.TryGetValue(key, out value) ? value : defaultValue;
        }
    }
}