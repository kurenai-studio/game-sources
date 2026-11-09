using JGM.Gameplay.Base;
using JGM.Gameplay.Creeps;
using JGM.Gameplay.Turrets;
using JGM.Gameplay.Turrets.Projectiles;
using JGM.Gameplay.Wallet;
using JGM.Gameplay.Waves;
using UnityEngine;

namespace JGM.Gameplay.Installer
{
    public class ServiceInstaller : MonoBehaviour
    {
        [Header("Initialization Data")]
        [SerializeField] private GameConfig gameConfig;
        [SerializeField] private Transform[] creepSpawnPoints;

        [Header("Service Instances")]
        [SerializeField] private Camera mainCamera;
        [SerializeField] private CoroutineService coroutineService;
        [SerializeField] private PlayerBase playerBase;

        private void Awake()
        {
            var serviceLocator = ServiceLocator.Instance;
            InstallMonoServices(serviceLocator);
            InstallServices(serviceLocator);
        }

        private void InstallMonoServices(ServiceLocator serviceLocator)
        {
            serviceLocator.Register<Camera>(mainCamera);
            serviceLocator.Register<CoroutineService>(coroutineService);
            playerBase.Initialize(gameConfig.PlayerStartHealth);
            serviceLocator.Register<PlayerBase>(playerBase);
        }

        private void InstallServices(ServiceLocator serviceLocator)
        {
            var creepSpawner = new CreepSpawner(creepSpawnPoints);
            serviceLocator.Register<CreepSpawner>(creepSpawner);
            var projectilePool = new ProjectilePool(gameConfig.ProjectilePoolConfig);
            serviceLocator.Register<ProjectilePool>(projectilePool);
            serviceLocator.Register<TurretSpawner>(new TurretSpawner(creepSpawner, projectilePool));
            serviceLocator.Register<WavesController>(new WavesController(gameConfig.WaveList));
            serviceLocator.Register<PlayerWallet>(new PlayerWallet(gameConfig.PlayerStartCoins));
        }
    }
}
