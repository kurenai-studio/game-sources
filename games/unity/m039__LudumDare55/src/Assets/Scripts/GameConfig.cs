using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LD55
{
    [CreateAssetMenu(fileName = "GameConfig", menuName = "LD55/GameConfig", order = 1)]
    public class GameConfig : ScriptableObject
    {
        static GameConfig s_Instance;

        public static GameConfig Instance
        {
            get
            {
                if (s_Instance == null)
                {
                    s_Instance = Resources.Load<GameConfig>("GameConfig");
                }

                return s_Instance;
            }
        }

        #region Inspector

        public Ghost ghostPrefab;

        public Projectile projectile;

        #endregion
    }
}
