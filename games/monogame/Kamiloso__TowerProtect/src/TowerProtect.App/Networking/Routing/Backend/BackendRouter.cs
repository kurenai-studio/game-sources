using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using TowerProtect.App.Networking.Routing.Backend;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Inventions.Networking;

namespace TowerProtect.App.Networking.Backend;

partial interface IBackendRouter : IUpdateAware;

[AutoInterface]
internal class BackendRouter(
    IBackendFrontPipe backendFrontPipe,
    IPacketSerializer packetSerializer) : IBackendRouter
{
    private readonly Dictionary<int, Action<long, string>> _callbacks = [];

    public void Update(double deltaTime)
    {
        while (backendFrontPipe.TryDequeue(out var msg))
        {
            var (client, message) = msg;

            if (!packetSerializer.TryExtractPayload(message, out int identifier, out string payload))
            {
                Console.WriteLine($"Failed to extract payload. Message: {message}");
                continue;
            }

            if (!_callbacks.TryGetValue(identifier, out Action<long, string>? action))
            {
                Console.WriteLine($"Unknown packet. Identifier: {identifier}");
                continue;
            }

            action(client, payload);
        }
    }

    public void Send<T>(long client, T packet) where T : struct, IPacket
    {
        backendFrontPipe.Send(client, packetSerializer.Serialize(packet));
    }

    public void Subscribe<T>(Action<long, T> callback) where T : struct, IPacket
    {
        _callbacks.Add(T.Identifier, (client, payload) =>
        {
            if (!packetSerializer.TryDeserialize(payload, out T packet) || !packet.IsValid())
            {
                Console.WriteLine($"Invalid packet data. Identifier: {T.Identifier}");
                return;
            }

            callback(client, packet);
        });
    }
}
