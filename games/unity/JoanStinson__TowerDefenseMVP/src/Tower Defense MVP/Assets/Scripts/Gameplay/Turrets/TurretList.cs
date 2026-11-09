using AYellowpaper;
using AYellowpaper.SerializedCollections;
using System;
using UnityEngine;

namespace JGM.Gameplay.Turrets
{
    [CreateAssetMenu(fileName = "New Turret List", menuName = "Turrets/Turret List")]
    public class TurretList : ScriptableObject
    {
        [SerializedDictionary("Turret Id", "Turret Prefab")]
        public SerializedDictionary<string, TurretPrefab> Turrets;

        public ITurret GetTurretById(string turretId)
        {
            Turrets.TryGetValue(turretId, out TurretPrefab turret);
            return turret.Prefab.Value;
        }

        [Serializable]
        public class TurretPrefab
        {
            public InterfaceReference<ITurret, MonoBehaviour> Prefab;
            public int Price = 5;
            public Color CardColor;
        }
    }
}
