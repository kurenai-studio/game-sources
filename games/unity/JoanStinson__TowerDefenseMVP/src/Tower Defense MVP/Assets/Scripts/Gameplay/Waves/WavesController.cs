using JGM.Gameplay.Creeps;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace JGM.Gameplay.Waves
{
    public class WavesController
    {
        public event Action<int> OnWaveStart;
        public event Action OnAllWavesComplete;
        public int WavesCount => waveList.Waves.Length;

        private WaveList waveList;
        private CreepSpawner creepSpawner;
        private CoroutineService coroutineService;
        private Wave currentWave;
        private int currentWaveIndex;
        private IEnumerator startWaveCoroutine;

        public WavesController(WaveList waveList)
        {
            this.waveList = waveList;
            var serviceLocator = ServiceLocator.Instance;
            creepSpawner = serviceLocator.Get<CreepSpawner>();
            coroutineService = serviceLocator.Get<CoroutineService>();
            creepSpawner.OnAllCreepsKilled += OnWaveCleared;
        }

        public void StartGame()
        {
            Restart();
            startWaveCoroutine = StartWave();
            coroutineService.Run(startWaveCoroutine);
        }

        private IEnumerator StartWave()
        {
            OnWaveStart?.Invoke(currentWaveIndex);
            yield return new WaitForSeconds(currentWave.StartWaveDelay);
            creepSpawner.Spawn(GetCreepsToSpawn(), currentWave.DelayBetweenCreeps);
        }

        private IReadOnlyList<ICreep> GetCreepsToSpawn()
        {
            int totalCreeps = 0;
            foreach (var creep in currentWave.Creeps)
            {
                totalCreeps += creep.CreepsCount;
            }

            var creepsToSpawn = new List<ICreep>(totalCreeps); // pre-allocate for performance

            foreach (var creep in currentWave.Creeps)
            {
                for (int i = 0; i < creep.CreepsCount; i++)
                {
                    creepsToSpawn.Add(creep.CreepPrefab.Value);
                }
            }

            creepsToSpawn.Shuffle();
            return creepsToSpawn;
        }

        private void OnWaveCleared()
        {
            if (ClearedLastWave())
            {
                OnAllWavesComplete?.Invoke();
            }
            else
            {
                currentWaveIndex++;
                currentWave = waveList.Waves[currentWaveIndex];
                coroutineService.Run(StartWave());
            }
        }

        private bool ClearedLastWave()
        {
            return currentWaveIndex >= waveList.Waves.Length - 1;
        }

        public void Restart()
        {
            coroutineService.Stop(startWaveCoroutine);
            currentWaveIndex = 0;
            currentWave = waveList.Waves[currentWaveIndex];
        }
    }
}
