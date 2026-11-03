using System;
using TowerProtect.App.Client.Camera;
using TowerProtect.App.Networking.Client;
using TowerProtect.App.Networking.Packets.Requests;
using TowerProtect.App.Networking.Packets.Responses;
using TowerProtect.Domain.Client.Entities;
using TowerProtect.Domain.Display.Tiles;
using TowerProtect.Domain.Inventions.Interfaces;

namespace TowerProtect.App.Client.Receivers;

partial interface IInformationDivider : IStartAware;

internal class InformationDivider(
    IWorldDisplay worldDisplay,
    IEntitiesDisplay entitiesDisplay,
    ICameraControl cameraControl,
    IClientRouter clientRouter) : IInformationDivider
{
    private Guid _playerGuid;

    public void Start()
    {
        clientRouter.Subscribe<InitializeDto>(OnInitialize);
        clientRouter.Subscribe<BroadcastDto>(OnBroadcast);

        clientRouter.Send(new HelloDto());
    }

    public void OnInitialize(InitializeDto initializeDto)
    {
        _playerGuid = initializeDto.PlayerGuid;
        var tilemapData = initializeDto.Tilemap;

        worldDisplay.PushInformation(tilemapData);
    }

    public void OnBroadcast(BroadcastDto broadcastDto)
    {
        var frameUnion = broadcastDto.ToFrameUnion(_playerGuid);

        cameraControl.Tick(frameUnion);
        entitiesDisplay.Tick(frameUnion);
    }
}
