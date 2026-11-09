using JGM.Gameplay.Base;
using JGM.Gameplay.Creeps;
using JGM.Gameplay.Turrets;
using JGM.Gameplay.Turrets.Projectiles;
using JGM.Gameplay.Wallet;
using JGM.Gameplay.Waves;
using System;
using UnityEngine;

namespace JGM.Gameplay
{
    public class GameController : MonoBehaviour
    {
        public event Action OnGameStart;

        private PlayerBase playerBase;
        private CreepSpawner creepSpawner;
        private ProjectilePool projectilePool;
        private TurretSpawner turretSpawner;
        private WavesController wavesController;
        private PlayerWallet playerWallet;

        private void Start()
        {
            var serviceLocator = ServiceLocator.Instance;
            playerBase = serviceLocator.Get<PlayerBase>();
            creepSpawner = serviceLocator.Get<CreepSpawner>();
            projectilePool = serviceLocator.Get<ProjectilePool>();
            turretSpawner = serviceLocator.Get<TurretSpawner>();
            wavesController = serviceLocator.Get<WavesController>();
            playerWallet = serviceLocator.Get<PlayerWallet>();
            creepSpawner.OnCreepKill += (creep) => playerWallet.AddCoins(creep.CoinReward);
            StartGame();
        }

        private void StartGame()
        {
            wavesController.StartGame();
            OnGameStart?.Invoke();
        }

        public void RestartGame()
        {
            playerBase.Restart();
            creepSpawner.Restart();
            projectilePool.Restart();
            turretSpawner.Restart();
            wavesController.Restart();
            playerWallet.Restart();
            StartGame();
        }
    }
}
