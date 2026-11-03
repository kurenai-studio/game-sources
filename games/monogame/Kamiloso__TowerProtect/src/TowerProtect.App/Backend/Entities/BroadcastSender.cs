using AutoInterfaceAttributes;
using TowerProtect.App.Networking.Backend;
using TowerProtect.App.Networking.Packets.Responses;
using TowerProtect.Domain.Backend.Entities.Bags;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Inventions.Tools;
using static TowerProtect.Domain.Config.PeriodConfig;

namespace TowerProtect.App.Backend.Entities;

partial interface IBroadcastSender : IUpdateAware;

[AutoInterface]
internal class BroadcastSender(
    IEntityBag entityBag,
    IBackendRouter backendRouter) : IBroadcastSender
{
    private readonly LoopCycle _broadcastCycle = new(BroadcastSendPeriod);

    public void Update(double deltaTime)
    {
        _broadcastCycle.StackInvoke(deltaTime, frames =>
        {
            double tickTime = frames * BroadcastSendPeriod;
            var entityList = entityBag.CollectEntityListData();

            backendRouter.Send(0, new BroadcastDto(entityList, tickTime));
        });
    }
}
