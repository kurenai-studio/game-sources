using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using TowerProtect.App.Networking.Routing.Backend;

namespace TowerProtect.App.Networking.Backend;

partial interface IBackendPipe : IBackendFrontPipe, IBackendBackPipe;

[AutoInterface]
internal class BackendPipe : IBackendPipe
{
    private readonly Queue<(long, string)> _buffer = [];

    public event Action<long, string>? OnSendEvent;

    public void PushMessage(long client, string message) => _buffer.Enqueue((client, message));
    public void Send(long client, string message) => OnSendEvent?.Invoke(client, message);
    public bool TryDequeue(out (long, string) msgPair) => _buffer.TryDequeue(out msgPair);
}
