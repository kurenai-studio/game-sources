using AutoInterfaceAttributes;
using System;
using TowerProtect.App.Client.Interfaces;
using TowerProtect.App.Networking.Client;
using TowerProtect.App.Networking.Packets.Requests;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Vectors;
using static TowerProtect.Domain.Config.PeriodConfig;

namespace TowerProtect.App.Client.Input;

partial interface IInputSender : IUpdateAware;

[AutoInterface]
internal class InputSender(
    IInputSystem inputSystem,
    IClientRouter clientRouter) : IInputSender
{
    private readonly LoopCycle _inputCycle = new(InputSendPeriod);

    public void Update(double deltaTime)
    {
        _inputCycle.StackInvoke(deltaTime, _ =>
        {
            Vec2 movementDirection = inputSystem.MouseVector;

            clientRouter.Send(new InputDto(
                Rotation: Math.Atan2(movementDirection.y, movementDirection.x),
                IsMoving: inputSystem.IsMousePressed(1) || inputSystem.IsKeyPressed("Space"),
                IsShooting: inputSystem.IsMousePressed(0)
            ));
        });
    }
}
