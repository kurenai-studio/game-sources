using JGM.Gameplay.Creeps;
using JGM.Gameplay.Turrets.Projectiles;
using System;
using System.Collections.Generic;
using UnityEngine;

namespace JGM.Gameplay.Turrets
{
    public class TurretSpawner
    {
        private CreepSpawner creepSpawner;
        private ProjectilePool projectilePool;

        private Transform turretsParent;
        private List<ITurret> activeTurrets = new();

        public TurretSpawner(CreepSpawner creepSpawner, ProjectilePool projectilePool)
        {
            this.creepSpawner = creepSpawner;
            this.projectilePool = projectilePool;
        }

        public void Spawn(ITurret turret, Vector3 position)
        {
            turretsParent ??= new GameObject("Turrets").transform;
            var spawnedTurret = GameObject.Instantiate(turret.GameObject, turretsParent, false);
            spawnedTurret.transform.position = position;
            var turretComponent = spawnedTurret.GetComponent<ITurret>();
            turretComponent.Initialize(creepSpawner, projectilePool);
            activeTurrets.Add(turretComponent);
        }

        public void Restart()
        {
            foreach (var turret in activeTurrets)
            {
                GameObject.Destroy(turret.GameObject);
            }
            activeTurrets.Clear();
        }
    }
}
