using JGM.Gameplay.Base;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace JGM.Gameplay.Creeps
{
    public class CreepSpawner
    {
        public event Action<ICreep> OnCreepKill;
        public event Action OnAllCreepsKilled;

        private Transform[] spawnPoints;
        private PlayerBase playerBase;
        private CoroutineService coroutineService;

        private List<ICreep> activeCreeps = new();
        private Transform creepsParent;
        private IEnumerator spawnCoroutine;
        private int totalCreepsToSpawn;
        private int activeCreepsSpawned;

        public CreepSpawner(Transform[] spawnPoints)
        {
            this.spawnPoints = spawnPoints;
            var serviceLocator = ServiceLocator.Instance;
            playerBase = serviceLocator.Get<PlayerBase>();
            coroutineService = serviceLocator.Get<CoroutineService>();
        }

        public void Spawn(IReadOnlyList<ICreep> creeps, float delayBetweenCreeps)
        {
            creepsParent ??= new GameObject("Creeps").transform;
            totalCreepsToSpawn = creeps.Count;
            activeCreepsSpawned = 0;
            spawnCoroutine = SpawnCreeps(creeps, delayBetweenCreeps);
            coroutineService.Run(spawnCoroutine);
        }

        private IEnumerator SpawnCreeps(IReadOnlyList<ICreep> creeps, float delayBetweenCreeps)
        {
            foreach (var creep in creeps)
            {
                var spawnedCreep = GameObject.Instantiate(creep.GameObject, creepsParent, false);
                int randomSpawnPoint = Random.Range(0, spawnPoints.Length);
                spawnedCreep.transform.position = spawnPoints[randomSpawnPoint].position;
                var activeCreep = spawnedCreep.GetComponent<ICreep>();
                activeCreep.Initialize(this, playerBase);
                activeCreeps.Add(activeCreep);
                activeCreepsSpawned++;
                yield return new WaitForSeconds(delayBetweenCreeps);
            }
        }

        public void KillCreep(Creep creep)
        {
            activeCreeps.Remove(creep);
            GameObject.Destroy(creep.gameObject);
            OnCreepKill?.Invoke(creep);

            if (AllCreepsKilled())
            {
                OnAllCreepsKilled?.Invoke();
            }
        }

        private bool AllCreepsKilled()
        {
            return activeCreeps.Count == 0 && activeCreepsSpawned == totalCreepsToSpawn;
        }

        public IEnumerable<ICreep> GetActiveCreeps()
        {
            foreach (var creep in activeCreeps)
            {
                yield return creep;
            }
        }

        public void Restart()
        {
            coroutineService.Stop(spawnCoroutine);

            foreach (var creep in activeCreeps)
            {
                GameObject.Destroy(creep.GameObject);
            }
            activeCreeps.Clear();

            totalCreepsToSpawn = 0;
            activeCreepsSpawned = 0;
        }
    }
}
