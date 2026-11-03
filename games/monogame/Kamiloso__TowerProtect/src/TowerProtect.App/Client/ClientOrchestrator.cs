using AutoInterfaceAttributes;
using TowerProtect.App.Client.Camera;
using TowerProtect.App.Client.Input;
using TowerProtect.App.Client.Receivers;
using TowerProtect.App.Networking.Client;
using TowerProtect.Domain.Client.Entities;
using TowerProtect.Domain.Inventions.Interfaces;

namespace TowerProtect.App.Client;

partial interface IClientOrchestrator : IStartAware, IUpdateAware;

[AutoInterface]
internal class ClientOrchestrator(
    IClientRouter clientRouter,
    IInformationDivider informationDivider,
    IInputSender inputSender,
    IEntitiesDisplay entitiesDisplay,
    ICameraControl cameraControl) : IClientOrchestrator
{
    public void Start()
    {
        informationDivider.Start();
    }

    public void Update(double deltaTime)
    {
        clientRouter.Update(deltaTime);
        inputSender.Update(deltaTime);
        entitiesDisplay.Update(deltaTime);
        cameraControl.Update(deltaTime);
    }
}
