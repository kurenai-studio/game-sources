using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using TowerProtect.App.Networking.Routing.Client;
using TowerProtect.App.Scopes;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Inventions.Networking;

namespace TowerProtect.App.Networking.Client;

file class RouterCrashException(string message) : Exception(message);

partial interface IClientRouter : IUpdateAware;

[AutoInterface]
internal class ClientRouter(
    IClientFrontPipe clientFrontPipe,
    IScopeSwitcher scopeSwitcher,
    IPacketSerializer packetSerializer) : IClientRouter
{
    private readonly Dictionary<int, Action<string>> _callbacks = [];

    public void Update(double deltaTime)
    {
        if (clientFrontPipe.IsDead())
        {
            scopeSwitcher.CrashToMenu("Client pipe marked as dead");
            return;
        }

        while (clientFrontPipe.TryDequeue(out string message))
        {
            try
            {
                if (!packetSerializer.TryExtractPayload(message, out int identifier, out string payload))
                    throw new RouterCrashException($"Invalid message format. Message: {message}");

                if (!_callbacks.TryGetValue(identifier, out Action<string>? action))
                    throw new RouterCrashException($"No callback for packet. Identifier: {identifier}");

                action(payload);
            }
            catch (RouterCrashException ex)
            {
                scopeSwitcher.CrashToMenu(ex);
                return;
            }
        }
    }

    public void Send<T>(T packet) where T : struct, IPacket
    {
        clientFrontPipe.Send(packetSerializer.Serialize(packet));
    }

    public void Subscribe<T>(Action<T> callback) where T : struct, IPacket
    {
        _callbacks.Add(T.Identifier, payload =>
        {
            if (!packetSerializer.TryDeserialize(payload, out T packet) || !packet.IsValid())
                throw new RouterCrashException($"Packet deserialization failed. Identifier: {T.Identifier}");

            callback(packet);
        });
    }
}
