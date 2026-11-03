using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using TowerProtect.Domain.Backend.Entities.Interactions.Input;
using TowerProtect.Domain.Backend.Entities.Specific;
using TowerProtect.Domain.Model.Unions;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Bags;

[AutoInterface]
internal class PlayerBag(IEntityBag entityBag) : IPlayerBag
{
    private readonly Dictionary<long, ManualController> _controllers = [];

    public bool Exists(long client)
        => _controllers.ContainsKey(client);

    public bool TrySpawn(long client, out Guid guid)
    {
        guid = Guid.Empty;

        if (_controllers.ContainsKey(client))
            return false;

        var controller = new ManualController();
        _controllers.Add(client, controller);

        var player = new PlayerEntity(Vec2.Zero, controller);
        entityBag.SpawnEntity(player, out guid);

        return true;
    }

    public void AcceptInput(long client, InputUnion inputUnion)
    {
        if (!_controllers.TryGetValue(client, out var controller))
            return;

        controller.AcceptInput(inputUnion);
    }
}
