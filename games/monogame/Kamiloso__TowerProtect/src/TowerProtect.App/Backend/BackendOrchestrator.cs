using AutoInterfaceAttributes;
using TowerProtect.App.Backend.Entities;
using TowerProtect.App.Networking.Backend;
using TowerProtect.Domain.Backend.Entities.Bags;
using TowerProtect.Domain.Inventions.Interfaces;

namespace TowerProtect.App.Backend;

partial interface IBackendOrchestrator : IStartAware, IUpdateAware;

[AutoInterface]
internal class BackendOrchestrator(
    IBackendRouter backendRouter,
    IEntityBag entityBag,
    IPlayerManager playerManager,
    IEnemyManager enemyManager,
    IBroadcastSender broadcastSender) : IBackendOrchestrator
{
    public void Start()
    {
        playerManager.Start();
    }

    public void Update(double deltaTime)
    {
        backendRouter.Update(deltaTime);
        entityBag.Update(deltaTime);
        enemyManager.Update(deltaTime);
        broadcastSender.Update(deltaTime);
    }
}
